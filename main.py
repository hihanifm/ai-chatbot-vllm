import streamlit as st
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage

st.set_page_config(
    page_title="LangChain + vLLM + Streamlit",
    page_icon="🤖",
    layout="wide"
)

st.header("🤖 LangChain + vLLM + Streamlit")

# Sidebar for configuration
with st.sidebar:
    st.title("⚙️ Configuration")
    system_prompt = st.text_area(
        label="System Prompt",
        value="You are a helpful AI assistant who answers questions in short sentences.",
        height=150
    )
    
    model_name = st.text_input(
        label="Model Name",
        value="mistralai/Mistral-7B-Instruct-v0.1"
    )
    
    api_base = st.text_input(
        label="API Base URL",
        value="http://localhost:8000/v1"
    )
    
    temperature = st.slider(
        label="Temperature",
        min_value=0.0,
        max_value=2.0,
        value=0.7,
        step=0.1
    )
    
    max_tokens = st.number_input(
        label="Max Tokens",
        min_value=1,
        max_value=4096,
        value=512,
        step=64
    )
    
    if st.button("🔄 Clear Chat History"):
        st.session_state.messages = []

# Function to get LLM instance (with caching based on key parameters)
@st.cache_resource
def get_llm(_api_base: str, _model_name: str, _temperature: float, _max_tokens: int):
    """Create LLM instance with caching based on parameters"""
    return ChatOpenAI(
        openai_api_key="EMPTY",  # vLLM doesn't require a key
        openai_api_base=_api_base,
        model_name=_model_name,
        temperature=_temperature,
        max_tokens=_max_tokens,
        streaming=False,
        timeout=60.0
    )

# Initialize chat history
if "messages" not in st.session_state:
    st.session_state.messages = [
        {"role": "assistant", "content": "Hello! How may I help you today? 🤖"}
    ]

# Display chat messages
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

# Chat input
if question := st.chat_input("Type your message here..."):
    # Add user message to chat history
    st.session_state.messages.append({"role": "user", "content": question})
    
    # Display user message
    with st.chat_message("user"):
        st.markdown(question)
    
    # Generate response
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            try:
                # Get LLM instance with current parameters
                llm = get_llm(api_base, model_name, temperature, max_tokens)
                
                # Create prompt with system message and conversation
                messages = [
                    SystemMessage(content=system_prompt),
                ]
                
                # Add conversation history (excluding system message)
                for msg in st.session_state.messages[:-1]:  # Exclude the current user message
                    if msg["role"] == "user":
                        messages.append(HumanMessage(content=msg["content"]))
                    elif msg["role"] == "assistant":
                        messages.append(AIMessage(content=msg["content"]))
                
                # Add current user message
                messages.append(HumanMessage(content=question))
                
                # Get response from LLM
                response = llm.invoke(messages)
                response_text = response.content if hasattr(response, 'content') else str(response)
                
                st.markdown(response_text)
                
                # Add assistant response to chat history
                st.session_state.messages.append({"role": "assistant", "content": response_text})
                
            except Exception as e:
                error_message = f"❌ Error: {str(e)}"
                st.error(error_message)
                st.info("💡 Make sure the vLLM server is running at the specified API base URL.")
