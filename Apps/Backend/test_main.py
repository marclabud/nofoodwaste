import os
import unittest

# Set test database path before importing app to avoid messing with development database
os.environ["DB_PATH"] = "test_food_waste.db"
os.environ["DB_PROVIDER"] = "sqlite"

from fastapi.testclient import TestClient
from main import app

class TestIngredientNameLength(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)

    @classmethod
    def tearDownClass(cls):
        # Remove the test database file
        if os.path.exists("test_food_waste.db"):
            try:
                os.remove("test_food_waste.db")
            except Exception as e:
                print(f"Error removing test database: {e}")

    def test_create_ingredient_success(self):
        # Exactly 100 characters for name should be allowed
        long_name = "a" * 100
        payload = {
            "name": long_name,
            "quantity": 2.5,
            "unit": "piece",
            "expiresAt": "2026-12-31"
        }
        response = self.client.post("/ingredients", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["name"], long_name)
        
        # Clean up by deleting the ingredient
        ing_id = data["id"]
        self.client.delete(f"/ingredients/{ing_id}")

    def test_create_ingredient_too_long(self):
        # 101 characters for name should be rejected with 422 Unprocessable Entity
        too_long_name = "a" * 101
        payload = {
            "name": too_long_name,
            "quantity": 2.5,
            "unit": "piece",
            "expiresAt": "2026-12-31"
        }
        response = self.client.post("/ingredients", json=payload)
        self.assertEqual(response.status_code, 422)
        
        # Verify validation error is specifically for the 'name' field
        errors = response.json()["detail"]
        self.assertTrue(any(error["loc"] == ["body", "name"] for error in errors))
        self.assertTrue(any(
            "less_than_equal" in error["type"] or 
            "string_too_long" in error["type"] or 
            "max_length" in error["type"] 
            for error in errors
        ))

    def test_create_ingredient_too_short(self):
        # Empty name should be rejected with 422 Unprocessable Entity
        payload = {
            "name": "",
            "quantity": 2.5,
            "unit": "piece",
            "expiresAt": "2026-12-31"
        }
        response = self.client.post("/ingredients", json=payload)
        self.assertEqual(response.status_code, 422)
        
        errors = response.json()["detail"]
        self.assertTrue(any(error["loc"] == ["body", "name"] for error in errors))
        self.assertTrue(any(
            "greater_than_equal" in error["type"] or 
            "string_too_short" in error["type"] or 
            "min_length" in error["type"] 
            for error in errors
        ))

if __name__ == "__main__":
    unittest.main()
