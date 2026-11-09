"""Send at most five replayable demo records through a Snowpipe Streaming Named Channel.

The connection profile lives outside this repository. Run --help for arguments.
"""

import argparse
from pathlib import Path
from uuid import uuid4


EVENTS = [
    {"SEQ": n, "EVENT_ID": f"event-{n:03}", "AMOUNT": n * 10, "STATUS": "accepted"}
    for n in range(1, 6)
]
CHANNEL_NAME = "D3_REPLAYABLE_EVENTS"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", required=True, type=Path, help="Path to your private SDK profile.json")
    parser.add_argument("--max-seq", type=int, choices=range(1, 6), default=5)
    args = parser.parse_args()

    if not args.profile.is_file():
        parser.error("The profile file does not exist")

    # Import only when actually ingesting, so --help works before SDK install.
    from snowflake.ingest.streaming import StreamingIngestClient

    client = StreamingIngestClient.from_table(
        client_name=f"d3-lab-{uuid4().hex[:8]}",
        db_name="D3_STREAMING_LAB",
        schema_name="LAB",
        table_name="EVENTS",
        profile_json=str(args.profile),
    )
    channel = None
    try:
        # Keep this name stable across runs. Snowflake returns the last offset
        # it committed, so the same retained source records can be replayed.
        channel, status = client.open_channel(CHANNEL_NAME)
        last_committed = status.latest_committed_offset_token
        start_seq = int(last_committed) + 1 if last_committed is not None else 1
        pending = [row for row in EVENTS if start_seq <= row["SEQ"] <= args.max_seq]
        print(f"Last committed offset: {last_committed}; rows to append: {len(pending)}")

        for row in pending:
            channel.append_row(row, str(row["SEQ"]))

        if pending:
            final_offset = pending[-1]["SEQ"]
            # One checkpoint after the bounded group, not a wait per row.
            channel.wait_for_commit(
                lambda token: token is not None and int(token) >= final_offset,
                timeout_seconds=60,
            )
            print(f"Committed through source offset {final_offset}")
        else:
            print("Nothing to send; this source range is already committed")
    finally:
        try:
            if channel is not None:
                channel.close()
        finally:
            client.close()


if __name__ == "__main__":
    main()
