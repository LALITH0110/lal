#!/bin/bash

# LAL - Natural Language to Shell Commands (Curl Version)
# Avoids all Python dependency and SSL issues

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default config path
CONFIG_DIR="$HOME/.config/lal"
CONFIG_FILE="$CONFIG_DIR/config"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR" 2>/dev/null

# Set default OS if not configured
LAL_OS="macos"

# Load config if exists
if [ -f "$CONFIG_FILE" ]; then
    # Load the OS setting directly
    LAL_OS_CONFIG=$(grep "^LAL_OS=" "$CONFIG_FILE" | cut -d'"' -f2)
    if [ -n "$LAL_OS_CONFIG" ]; then
        LAL_OS="$LAL_OS_CONFIG"
    fi
fi

show_help() {
    echo "🚀 LAL - Natural Language to Shell Commands"
    echo ""
    echo "Convert natural language descriptions into shell commands using AI."
    echo ""
    echo "💡 Usage:"
    echo "  lal \"your command description\""
    echo ""
    echo "🌟 Examples:"
    echo "  lal \"git push\"                           # Git operations"
    echo "  lal \"what's running on port 8000\"        # Process monitoring"
    echo "  lal \"find large files\"                   # File operations"
    echo "  lal \"list all docker containers\"         # Docker management"
    echo "  lal \"compress this folder\"               # Archive operations"
    echo "  lal \"show disk usage\"                    # System information"
    echo "  lal \"kill process on port 3000\"          # Process management"
    echo "  lal \"check network connections\"          # Network diagnostics"
    echo ""
    echo "⚡ Quick Execution:"
    echo "  lal \"list files\" -e                      # Execute immediately"
    echo "  lal \"git status\" --execute               # Same as -e"
    echo ""
    echo "🔧 Options:"
    echo "  -e, --execute    Execute the command immediately (with confirmation)"
    echo "  -c, --copy       Copy the command to clipboard"
    echo "  --os             Change your operating system setting (Windows/macOS/Linux)"
    echo "  --cheat          Get common command snippets for a technology"
    echo "                   Example: lal --cheat nginx"
    echo "  --help, -h       Show this detailed help"
    echo ""
    echo "💡 Tips:"
    echo "  • Be specific: 'list files with details' vs 'list files'"
    echo "  • Mention tools: 'docker containers' vs 'containers'"
    echo "  • Always review commands before using -e flag"
    echo "  • LAL works from any directory"
}

set_os_config() {
    echo ""
    echo "🖥️  Operating System Configuration"
    echo ""
    echo "Select your operating system:"
    echo "1) macOS (default)"
    echo "2) Linux"
    echo "3) Windows"
    echo ""
    read -p "Enter your choice [1-3]: " os_choice
    
    case $os_choice in
        1|"")
            LAL_OS="macos"
            echo "Setting OS to macOS"
            ;;
        2)
            LAL_OS="linux"
            echo "Setting OS to Linux"
            ;;
        3)
            LAL_OS="windows"
            echo "Setting OS to Windows"
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Using macOS as default.${NC}"
            LAL_OS="macos"
            ;;
    esac
    
    # Save the OS setting
    mkdir -p "$CONFIG_DIR" 2>/dev/null
    echo "LAL_OS=\"$LAL_OS\"" > "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ OS setting saved to $CONFIG_FILE${NC}"
    echo -e "${GREEN}✅ Selected OS: $LAL_OS${NC}"
    echo ""
}

show_config() {
    echo "🔧 LAL Configuration & Setup Guide"
    echo ""
    echo "📊 Current Configuration:"
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "  Anthropic API Key: ✅ Set (${ANTHROPIC_API_KEY:0:8}...)"
    else
        echo "  Anthropic API Key: ❌ Not set"
    fi
    
    if [ -n "$OPENAI_API_KEY" ]; then
        echo "  OpenAI API Key: ✅ Set (${OPENAI_API_KEY:0:8}...)"
    else
        echo "  OpenAI API Key: ❌ Not set"
    fi
    
    # Show OS configuration - simpler approach to display
    echo "  Operating System: $LAL_OS"
    
    echo ""
    
    if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
        echo -e "${YELLOW}⚠️  No API keys found. You need at least one to use LAL.${NC}"
        echo ""
    fi
    
    echo "🚀 Setup Guide:"
    echo ""
    echo "1️⃣  Get an API Key (choose one):"
    echo ""
    echo "   🤖 Anthropic (Recommended for Apple Silicon):"
    echo "      • Visit: https://console.anthropic.com/"
    echo "      • Sign up/Login → Go to 'API Keys'"
    echo "      • Create a new key → Copy it"
    echo ""
    echo "   🧠 OpenAI (Alternative):"
    echo "      • Visit: https://platform.openai.com/api-keys"
    echo "      • Sign up/Login → Create new secret key"
    echo "      • Copy the key (starts with 'sk-')"
    echo ""
    echo "2️⃣  Add to Environment (choose method):"
    echo ""
    echo "   Method A - Permanent (Recommended):"
    echo "      echo 'export ANTHROPIC_API_KEY=\"your-key-here\"' >> ~/.zshrc"
    echo "      source ~/.zshrc"
    echo ""
    echo "   Method B - Session Only:"
    echo "      export ANTHROPIC_API_KEY=\"your-key-here\""
    echo ""
    echo "   Method C - Via .env file:"
    echo "      echo 'ANTHROPIC_API_KEY=your-key-here' >> ~/.env"
    echo ""
    echo "3️⃣  Set your operating system:"
    echo "      lal --os"
    echo ""
    echo "4️⃣  Test Installation:"
    echo "      lal \"list files\""
    echo ""
    echo "💡 Notes:"
    echo "   • LAL prefers Anthropic if both keys are set"
    echo "   • API keys are loaded automatically from environment"
    echo "   • Keys are stored securely and never transmitted except to AI services"
    echo "   • Most API providers offer free tiers for testing"
    
    # Ask if user wants to configure OS
    echo ""
    read -p "Do you want to configure your operating system now? [y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        set_os_config
    fi
}

call_anthropic() {
    local prompt="$1"
    local system_prompt="You are a command-line expert. Convert natural language requests into shell commands for $LAL_OS operating system. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: git push -> git push, what's running on port 8000 -> lsof -i :8000, list all files -> ls -la, what is git -> null, tell me about linux -> null. For requests about writing essays or generating text, use a heredoc syntax to save the text to a file, but DO NOT include the full text content - just show the command structure. For example: 'write an essay about rice' -> cat > essay.txt << EOF\\nEssay text would go here\\nEOF"
    
    # Add Windows-specific guidance if needed
    if [ "$LAL_OS" = "windows" ]; then
        system_prompt="You are a command-line expert for Windows. Convert natural language requests into Windows CMD or PowerShell commands. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: list files -> dir, create folder -> mkdir foldername, find text -> findstr \"text\" file.txt, what is windows -> null, explain powershell -> null."
    fi

    # Escape quotes in system prompt for JSON
    system_prompt_escaped=$(echo "$system_prompt" | sed 's/"/\\"/g')

    # Add timeout to prevent hanging
    local response=$(curl -s --max-time 10 https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"claude-3-5-haiku-20241022\",
            \"max_tokens\": 200,
            \"temperature\": 0.1,
            \"system\": \"$system_prompt_escaped\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Command: $prompt\"}]
        }")
    
    # Handle curl errors (timeout, connection issues)
    if [ $? -ne 0 ]; then
        echo -e "${RED}API connection error or timeout${NC}" >&2
        echo "null"
        return 1
    fi
    
    # Debug API response if it contains error
    if echo "$response" | grep -q "\"error\""; then
        echo "API Error: $(echo "$response" | jq -r '.error.message' 2>/dev/null)" >&2
        echo "null"
        return 1
    fi
    
    # Extract command from JSON response using jq
    local command=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)
    
    # Check if response is null or a question answer
    if [ -z "$command" ] || [ "$command" = "null" ]; then
        echo "null"
        return 1
    elif [[ "$command" == "null" ]]; then
        echo "null"
        return 1
    else
        # Return the command
        echo "$command"
        return 0
    fi
}

call_openai() {
    local prompt="$1"
    local system_prompt="You are a command-line expert. Convert natural language requests into shell commands for $LAL_OS operating system. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: git push -> git push, what's running on port 8000 -> lsof -i :8000, list all files -> ls -la, what is git -> null, tell me about linux -> null. For requests about writing essays or generating text, use a heredoc syntax to save the text to a file, but DO NOT include the full text content - just show the command structure. For example: 'write an essay about rice' -> cat > essay.txt << EOF\\nEssay text would go here\\nEOF"
    
    # Add Windows-specific guidance if needed
    if [ "$LAL_OS" = "windows" ]; then
        system_prompt="You are a command-line expert for Windows. Convert natural language requests into Windows CMD or PowerShell commands. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: list files -> dir, create folder -> mkdir foldername, find text -> findstr \"text\" file.txt, what is windows -> null, explain powershell -> null."
    fi

    # Escape quotes in system prompt for JSON
    system_prompt_escaped=$(echo "$system_prompt" | sed 's/"/\\"/g')

    # Add timeout to prevent hanging
    local response=$(curl -s --max-time 10 https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-4o-mini\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"$system_prompt_escaped\"},
                {\"role\": \"user\", \"content\": \"Command: $prompt\"}
            ],
            \"max_tokens\": 200,
            \"temperature\": 0.1
        }")
    
    # Handle curl errors (timeout, connection issues)
    if [ $? -ne 0 ]; then
        echo -e "${RED}API connection error or timeout${NC}" >&2
        echo "null"
        return 1
    fi
    
    # Debug API response if it contains error
    if echo "$response" | grep -q "\"error\""; then
        echo "API Error: $(echo "$response" | jq -r '.error.message' 2>/dev/null)" >&2
        echo "null"
        return 1
    fi
    
    # Extract command from JSON response using jq
    local command=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    # Check if response is null or a question answer
    if [ -z "$command" ] || [ "$command" = "null" ]; then
        echo "null"
        return 1
    elif [[ "$command" == "null" ]]; then
        echo "null" 
        return 1
    else
        # Return the command
        echo "$command"
        return 0
    fi
}

# Copy text to clipboard based on OS
copy_to_clipboard() {
    local text="$1"
    
    case "$LAL_OS" in
        macos)
            echo "$text" | pbcopy
            return $?
            ;;
        linux)
            # Try different clipboard commands
            if command -v xclip >/dev/null 2>&1; then
                echo "$text" | xclip -selection clipboard
                return $?
            elif command -v xsel >/dev/null 2>&1; then
                echo "$text" | xsel -ib
                return $?
            elif command -v wl-copy >/dev/null 2>&1; then
                echo "$text" | wl-copy
                return $?
            else
                echo -e "${YELLOW}Clipboard utilities not found. Install xclip, xsel, or wl-copy.${NC}" >&2
                return 1
            fi
            ;;
        windows)
            # For Windows users using WSL or Git Bash
            if command -v clip.exe >/dev/null 2>&1; then
                echo "$text" | clip.exe
                return $?
            else
                echo -e "${YELLOW}Windows clipboard access not available.${NC}" >&2
                return 1
            fi
            ;;
        *)
            echo -e "${YELLOW}Clipboard not supported for this OS.${NC}" >&2
            return 1
            ;;
    esac
}

# Check if a command is potentially dangerous
is_dangerous_command() {
    local cmd="$1"
    
    # Simple substring checks for common dangerous commands
    if [[ "$cmd" == *"rm "* || "$cmd" == "rm" || 
          "$cmd" == *"sudo "* || 
          "$cmd" == *"kill "* || "$cmd" == *"killall "* ||
          "$cmd" == *"pkill "* || "$cmd" == *"dd "* ||
          "$cmd" == *"mkfs"* || "$cmd" == *"fdisk"* ||
          "$cmd" == *"chmod "* || "$cmd" == *"chown "* ||
          "$cmd" == *"rmdir "* || "$cmd" == "rmdir" ||
          "$cmd" == *"mv / "* || "$cmd" == *"mv /* "* ||
          "$cmd" == *"> /etc/"* || "$cmd" == *"> /dev/"* ||
          "$cmd" == *"> /sys/"* || "$cmd" == *"> /proc/"* ||
          "$cmd" == *"format"* || "$cmd" == *"wipe"* ||
          "$cmd" == *"delete"* || "$cmd" == *"destroy"* ]]; then
        return 0 # True, command is dangerous
    fi
    
    # Windows-specific dangerous commands
    if [ "$LAL_OS" = "windows" ]; then
        if [[ "$cmd" == *"del "* || "$cmd" == *"rd "* ||
              "$cmd" == *"rmdir "* || "$cmd" == *"format "* ||
              "$cmd" == *"taskkill "* || "$cmd" == *"Remove-Item"* ]]; then
            return 0 # True, command is dangerous
        fi
    fi
    
    # Check for potentially dangerous command piped to something
    if [[ "$cmd" == *"rm "*"|"* || 
          "$cmd" == *"dd "*"|"* || 
          "$cmd" == *"sudo "*"|"* ]]; then
        return 0 # True, command is dangerous
    fi
    
    return 1 # False, command is not dangerous
}

# Get cheat sheet for a technology
get_cheat_sheet() {
    local topic="$1"
    
    # Use Claude for cheat sheet generation
    local system_prompt="You are a command-line expert. Generate a concise cheat sheet with the most useful command examples for the specified technology. Format as a list of commands with VERY brief explanations (max 1 line per command). Include only the most important/common commands. Limit to 10-15 commands maximum."
    
    # Escape quotes in system prompt for JSON
    system_prompt_escaped=$(echo "$system_prompt" | sed 's/"/\\"/g')
    
    echo -e "${YELLOW}Generating cheat sheet for ${GREEN}$topic${YELLOW}...${NC}"
    
    # Call API based on available key
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        local response=$(curl -s --max-time 15 https://api.anthropic.com/v1/messages \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "{
                \"model\": \"claude-3-5-haiku-20241022\",
                \"max_tokens\": 1000,
                \"temperature\": 0.1,
                \"system\": \"$system_prompt_escaped\",
                \"messages\": [{\"role\": \"user\", \"content\": \"Generate a cheat sheet for: $topic\"}]
            }")
        
        # Handle curl errors
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Failed to connect to Anthropic API${NC}"
            return 1
        fi
        
        # Check for API errors
        if echo "$response" | grep -q "\"error\""; then
            echo -e "${RED}API Error: $(echo "$response" | jq -r '.error.message' 2>/dev/null)${NC}"
            return 1
        fi
        
        # Extract and print cheat sheet
        local cheat_content=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)
        if [ -z "$cheat_content" ]; then
            echo -e "${RED}Error: Failed to generate cheat sheet${NC}"
            return 1
        fi
        
        echo ""
        echo -e "${BLUE}📋 CHEAT SHEET: ${GREEN}$topic${NC}"
        echo -e "${BLUE}=====================================${NC}"
        echo "$cheat_content"
        echo -e "${BLUE}=====================================${NC}"
        
    elif [ -n "$OPENAI_API_KEY" ]; then
        local response=$(curl -s --max-time 15 https://api.openai.com/v1/chat/completions \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            -d "{
                \"model\": \"gpt-4o-mini\",
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"$system_prompt_escaped\"},
                    {\"role\": \"user\", \"content\": \"Generate a cheat sheet for: $topic\"}
                ],
                \"max_tokens\": 1000,
                \"temperature\": 0.1
            }")
        
        # Handle curl errors
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Failed to connect to OpenAI API${NC}"
            return 1
        fi
        
        # Check for API errors
        if echo "$response" | grep -q "\"error\""; then
            echo -e "${RED}API Error: $(echo "$response" | jq -r '.error.message' 2>/dev/null)${NC}"
            return 1
        fi
        
        # Extract and print cheat sheet
        local cheat_content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
        if [ -z "$cheat_content" ]; then
            echo -e "${RED}Error: Failed to generate cheat sheet${NC}"
            return 1
        fi
        
        echo ""
        echo -e "${BLUE}📋 CHEAT SHEET: ${GREEN}$topic${NC}"
        echo -e "${BLUE}=====================================${NC}"
        echo "$cheat_content"
        echo -e "${BLUE}=====================================${NC}"
    else
        echo -e "${RED}Error: No API keys found for cheat sheet generation${NC}"
        return 1
    fi
    
    return 0
}

# Main script
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Process special flags first
case "$1" in
    --help|-h)
        show_help
        exit 0
        ;;
    --config)
        show_config
        exit 0
        ;;
    --os)
        set_os_config
        exit 0
        ;;
    --cheat)
        if [ -z "$2" ]; then
            echo -e "${YELLOW}Usage: lal --cheat TOPIC${NC}"
            echo -e "Example: lal --cheat nginx"
            exit 1
        fi
        get_cheat_sheet "$2"
        exit $?
        ;;
    -*)
        echo -e "${RED}❌ Unknown option: $1${NC}"
        echo "Run 'lal --help' for usage information"
        exit 1
        ;;
esac

# Check for execute flag
EXECUTE=false
COPY=false
PROMPT=""

# Check if the first argument looks like a command
if [[ $# -gt 0 && "$1" != -* ]]; then
    PROMPT="$1"
    
    # If we received multiple arguments and there are no flags, it's likely the user forgot quotes
    if [[ $# -gt 1 && ! "$*" =~ "-e" && ! "$*" =~ "--execute" && ! "$*" =~ "-c" && ! "$*" =~ "--copy" ]]; then
        echo -e "${RED}❌ Error: Multi-word prompts must be enclosed in quotes${NC}"
        echo -e "  ${RED}✗ lal $PROMPT ${*:2}${NC}"
        echo -e "  ${GREEN}✓ lal \"$PROMPT ${*:2}\"${NC}"
        echo ""
        echo -e "${YELLOW}This requirement ensures your entire prompt is processed correctly.${NC}"
        exit 1
    fi
fi

# Process remaining args
for arg in "${@:2}"; do
    case $arg in
        -e|--execute)
            EXECUTE=true
            ;;
        -c|--copy)
            COPY=true
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $arg${NC}"
            echo "Run 'lal --help' for usage information"
            exit 1
            ;;
        *)
            # Ignore additional words if they're likely part of an unquoted prompt
            ;;
    esac
done

if [ -z "$PROMPT" ]; then
    echo -e "${YELLOW}💡 Usage: lal \"your command description\"${NC}"
    echo ""
    echo "Examples:"
    echo "  lal \"git push\""
    echo "  lal \"what's running on port 8000\""
    echo "  lal \"find large files\""
    echo ""
    echo "Configuration:"
    echo "  lal --os      (to set your operating system)"
    echo "  lal --help    (for detailed help)"
    exit 1
fi

# Check for API keys
    if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
        echo -e "${RED}❌ No API keys found. Set ANTHROPIC_API_KEY or OPENAI_API_KEY${NC}"
        echo ""
        echo "To set up your API key:"
        echo "1. Get an API key from:"
        echo "   • Anthropic: https://console.anthropic.com/"
        echo "   
        echo ""
        echo "2. Set it in your terminal:"
        echo "   export ANTHROPIC_API_KEY=\"your-key-here\""
        echo ""
        echo "3. For permanent use, add to your shell config:"
        echo "   echo 'export ANTHROPIC_API_KEY=\"your-key-here\"' >> ~/.zshrc"
        echo "   source ~/.zshrc"
        echo ""
        echo "For more details, run: lal --config"
        exit 1
    fi

# Generate command
echo -e "${YELLOW}Thinking...${NC}"

# Debug info - suppress from normal output
# echo -e "${BLUE}Using OS: $LAL_OS${NC}" >&2

if [ -n "$ANTHROPIC_API_KEY" ]; then
    COMMAND=$(call_anthropic "$PROMPT")
    CMD_STATUS=$?
else
    COMMAND=$(call_openai "$PROMPT")
    CMD_STATUS=$?
fi

# Check if the API call indicated this was a question (non-zero status)
if [ $CMD_STATUS -ne 0 ]; then
    echo ""
    if [ "$COMMAND" = "null" ]; then
        echo -e "${YELLOW}This appears to be a question, not a command request.${NC}"
        echo -e "${YELLOW}Try asking for a specific command action instead.${NC}"
    else
        echo -e "${RED}Failed to generate command${NC}"
    fi
    exit 1
fi

if [ -z "$COMMAND" ]; then
    echo ""
    echo -e "${RED}Failed to generate command${NC}"
    exit 1
fi

# Display result
echo ""
echo -e "${GREEN}${COMMAND}${NC}"

# Check if command is potentially dangerous
if is_dangerous_command "$COMMAND"; then
    echo -e "${RED}Warning: This command is potentially destructive/dangerous.${NC}"
    echo -e "${YELLOW}Review carefully before running manually. Execution disabled.${NC}"
    EXECUTE=false
fi

# Execute if requested
if [ "$EXECUTE" = true ]; then
    echo ""
    
    # Second safety check before execution
    if is_dangerous_command "$COMMAND"; then
        echo -e "${RED}⚠️  Cannot execute: Potentially dangerous command.${NC}"
        echo -e "${RED}⚠️  For your safety, execution of this command is disabled.${NC}"
        echo -e "${YELLOW}You may copy and run it manually if you're certain it's safe.${NC}"
    else
        read -p "Execute this command? [y/n]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Executing: $COMMAND${NC}"
            eval "$COMMAND"
        fi
    fi
else
    echo ""
    echo -e "${BLUE}Use -e flag to execute immediately${NC}"
fi

# Copy to clipboard if requested
if [ "$COPY" = true ]; then
    copy_to_clipboard "$COMMAND"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Command copied to clipboard${NC}"
    else
        echo -e "${RED}❌ Failed to copy to clipboard${NC}"
    fi
fi 