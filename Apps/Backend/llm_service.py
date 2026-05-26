import os

class LLMProvider:
    """
    Acts as the LLM connection provider. It encapsulates connection strings,
    validates model selections, and resolves LLM choices to actual model identifiers.
    """
    def __init__(self):
        # We can configure default mappings or handle clients here if needed
        self._default_model = os.getenv("LLM_MODEL", "gemini-2.5-flash")
        
        # Supported models mapping
        self._supported_models = {
            "gemini-2.5-flash": "gemini-2.5-flash",
            "gemini-2.5-pro": "gemini-2.5-pro",
            "default": self._default_model
        }

    def get_model(self, llm_choice: str) -> str:
        """
        Resolves the chosen LLM constant to the actual model identifier/connection string.
        """
        resolved_model = self._supported_models.get(llm_choice)
        if not resolved_model:
            raise ValueError(
                f"Unsupported LLM Choice: '{llm_choice}'. "
                f"Must be one of {list(self._supported_models.keys())}"
            )
            
        print(f"🔌 [LLMProvider] Resolved LLM choice '{llm_choice}' to model: '{resolved_model}'")
        return resolved_model

# Global LLM Provider instance (Singleton)
llm_provider = LLMProvider()
