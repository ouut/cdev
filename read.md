docker build -t my-vscode-web .


docker run -d \
  --name vscode-web \
  -p 8000:8000 \
  -v $(pwd):/workspace \
  --restart unless-stopped \
  my-vscode-web
