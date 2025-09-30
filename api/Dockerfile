FROM swift:6.1.2-focal

# useful debugging and core tools
RUN apt-get update && apt-get install -y \
    gdb lldb htop strace \
    net-tools curl vim tree \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# copy api and dependencies
COPY api ./api
COPY duet ./duet
COPY gertie ./gertie
COPY pairql ./pairql
COPY pairql-macapp ./pairql-macapp
COPY pairql-iosapp ./pairql-iosapp
COPY ts-interop ./ts-interop
COPY x-aws ./x-aws
COPY x-postmark ./x-postmark
COPY x-slack ./x-slack
COPY x-stripe ./x-stripe
COPY x-expect ./x-expect
COPY x-kit ./x-kit
COPY x-http ./x-http

WORKDIR /app/api

RUN swift build -c debug

EXPOSE 8080

CMD ["bash"]
