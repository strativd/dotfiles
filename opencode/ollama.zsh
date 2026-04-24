export OLLAMA_CURSOR_MODEL="gemma4:26b"

# Limit memory usage
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_NUM_GPU=1
export OLLAMA_MAX_LOADED_MODELS=1

# Set security settings
export OLLAMA_HOST=127.0.0.1:11434
export OLLAMA_ORIGINS='http://localhost,http://127.0.0.1,vscode-webview://*'
