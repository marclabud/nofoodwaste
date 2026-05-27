export interface paths {
  "/health": {
    get: {
      responses: {
        200: {
          content: {
            "application/json": {
              status: string;
              message: string;
            };
          };
        };
      };
    };
  };
  "/ingredients": {
    get: {
      responses: {
        200: {
          content: {
            "application/json": components["schemas"]["Ingredient"][];
          };
        };
      };
    };
    post: {
      requestBody: {
        content: {
          "application/json": components["schemas"]["IngredientCreate"];
        };
      };
      responses: {
        200: {
          content: {
            "application/json": components["schemas"]["Ingredient"];
          };
        };
      };
    };
  };
  "/ingredients/{ingredient_id}": {
    put: {
      parameters: {
        path: {
          ingredient_id: string;
        };
      };
      requestBody: {
        content: {
          "application/json": components["schemas"]["IngredientCreate"];
        };
      };
      responses: {
        200: {
          content: {
            "application/json": components["schemas"]["Ingredient"];
          };
        };
      };
    };
    delete: {
      parameters: {
        path: {
          ingredient_id: string;
        };
      };
      responses: {
        200: {
          content: {
            "application/json": {
              message: string;
            };
          };
        };
      };
    };
  };
  "/recipes/generate": {
    post: {
      requestBody: {
        content: {
          "application/json": components["schemas"]["GenerateRecipeRequest"];
        };
      };
      responses: {
        200: {
          content: {
            "application/json": components["schemas"]["RecipeResponse"];
          };
        };
      };
    };
  };
}

export interface components {
  schemas: {
    Ingredient: {
      id: string;
      name: string;
      quantity: number;
      unit: "g" | "kg" | "ml" | "l" | "piece";
      expiresAt: string;
      createdAt: string;
    };
    IngredientCreate: {
      name: string;
      quantity: number;
      unit: "g" | "kg" | "ml" | "l" | "piece";
      expiresAt: string;
    };
    Recipe: {
      title: string;
      matchScore: number;
      foodWastePriorityReason: string;
      estimatedTimeMinutes: number;
      usedIngredients: string[];
      missingRequiredIngredients: string[];
      optionalIngredients: string[];
      steps: string[];
      explanation: string;
    };
    RecipeResponse: {
      recipes: components["schemas"]["Recipe"][];
    };
    GenerateRecipeRequest: {
      ingredient_ids: string[];
    };
  };
}
