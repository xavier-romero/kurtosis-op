docker build -t xavierromero/op-tools . -f Dockerfile_op_tools
docker push xavierromero/op-tools:latest

docker build -t xavierromero/op . -f Dockerfile_op
docker push xavierromero/op:latest
