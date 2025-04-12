
FROM debian:bullseye-slim

ENV TERM xterm

RUN apt-get update && \
    apt-get install -y bash coreutils ncurses-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY game.sh /snake.sh

RUN chmod +x /snake.sh

CMD ["stdbuf", "-o0", "bash", "/snake.sh"]
