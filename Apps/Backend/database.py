from abc import ABC, abstractmethod
import sqlite3
import os
from contextlib import contextmanager
from typing import List, Optional

from models import Ingredient, IngredientCreate

class DatabaseProvider(ABC):
    @abstractmethod
    def init_db(self) -> None:
        """Initialize the database schema/settings if needed."""
        pass

    @abstractmethod
    def create_ingredient(self, ingredient: Ingredient) -> Ingredient:
        """Insert or set an ingredient in the database."""
        pass

    @abstractmethod
    def get_ingredients(self) -> List[Ingredient]:
        """Fetch all ingredients sorted by expiresAt ascending."""
        pass

    @abstractmethod
    def get_ingredients_by_ids(self, ingredient_ids: List[str]) -> List[Ingredient]:
        """Fetch ingredients matching the list of IDs."""
        pass

    @abstractmethod
    def delete_ingredient(self, ingredient_id: str) -> bool:
        """Delete an ingredient. Returns True if deleted, False if not found."""
        pass

    @abstractmethod
    def update_ingredient(self, ingredient_id: str, ingredient_in: IngredientCreate, created_at: str) -> Ingredient:
        """Update an existing ingredient."""
        pass


class SQLiteProvider(DatabaseProvider):
    def __init__(self, db_path: str):
        self.db_path = db_path

    @contextmanager
    def _get_db(self):
        conn = sqlite3.connect(self.db_path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        finally:
            conn.close()

    def init_db(self) -> None:
        with self._get_db() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS ingredients (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    quantity REAL NOT NULL,
                    unit TEXT NOT NULL,
                    expiresAt TEXT NOT NULL,
                    createdAt TEXT NOT NULL
                )
            ''')
            conn.commit()

    def create_ingredient(self, ingredient: Ingredient) -> Ingredient:
        with self._get_db() as conn:
            cursor = conn.cursor()
            cursor.execute(
                '''
                INSERT INTO ingredients (id, name, quantity, unit, expiresAt, createdAt)
                VALUES (?, ?, ?, ?, ?, ?)
                ''',
                (ingredient.id, ingredient.name, ingredient.quantity, ingredient.unit, ingredient.expiresAt, ingredient.createdAt)
            )
            conn.commit()
        return ingredient

    def get_ingredients(self) -> List[Ingredient]:
        with self._get_db() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM ingredients ORDER BY expiresAt ASC')
            rows = cursor.fetchall()
        return [Ingredient(**dict(row)) for row in rows]

    def get_ingredients_by_ids(self, ingredient_ids: List[str]) -> List[Ingredient]:
        if not ingredient_ids:
            return []
        with self._get_db() as conn:
            cursor = conn.cursor()
            placeholders = ','.join('?' for _ in ingredient_ids)
            query = f'SELECT * FROM ingredients WHERE id IN ({placeholders})'
            cursor.execute(query, ingredient_ids)
            rows = cursor.fetchall()
        return [Ingredient(**dict(row)) for row in rows]

    def delete_ingredient(self, ingredient_id: str) -> bool:
        with self._get_db() as conn:
            cursor = conn.cursor()
            cursor.execute('DELETE FROM ingredients WHERE id = ?', (ingredient_id,))
            rowcount = cursor.rowcount
            conn.commit()
        return rowcount > 0

    def update_ingredient(self, ingredient_id: str, ingredient_in: IngredientCreate, created_at: str) -> Ingredient:
        ingredient = Ingredient(
            id=ingredient_id,
            createdAt=created_at,
            **ingredient_in.model_dump()
        )
        with self._get_db() as conn:
            cursor = conn.cursor()
            cursor.execute(
                '''
                UPDATE ingredients 
                SET name = ?, quantity = ?, unit = ?, expiresAt = ?
                WHERE id = ?
                ''',
                (ingredient.name, ingredient.quantity, ingredient.unit, ingredient.expiresAt, ingredient_id)
            )
            conn.commit()
        return ingredient


class FirestoreProvider(DatabaseProvider):
    def __init__(self):
        try:
            from google.cloud import firestore
            self.db = firestore.Client()
            self.collection_name = "ingredients"
        except Exception as e:
            raise RuntimeError(
                f"Failed to initialize Firestore Client. "
                f"Ensure google-cloud-firestore package is installed and "
                f"GOOGLE_APPLICATION_CREDENTIALS or active GCP project context is configured. "
                f"Error: {str(e)}"
            )

    def init_db(self) -> None:
        # Cloud Firestore is schema-less and automatically handles collection creation.
        pass

    def create_ingredient(self, ingredient: Ingredient) -> Ingredient:
        doc_ref = self.db.collection(self.collection_name).document(ingredient.id)
        doc_ref.set(ingredient.model_dump())
        return ingredient

    def get_ingredients(self) -> List[Ingredient]:
        docs = self.db.collection(self.collection_name).order_by("expiresAt").stream()
        return [Ingredient(**doc.to_dict()) for doc in docs]

    def get_ingredients_by_ids(self, ingredient_ids: List[str]) -> List[Ingredient]:
        if not ingredient_ids:
            return []
        
        results = []
        # Firestore has a 30-item limit for 'in' queries. Chunk list just in case.
        for i in range(0, len(ingredient_ids), 30):
            chunk = ingredient_ids[i:i+30]
            docs = self.db.collection(self.collection_name).where("id", "in", chunk).stream()
            results.extend([Ingredient(**doc.to_dict()) for doc in docs])
        
        return results

    def delete_ingredient(self, ingredient_id: str) -> bool:
        doc_ref = self.db.collection(self.collection_name).document(ingredient_id)
        # Check existence first to return success/not-found correctly
        doc = doc_ref.get()
        if not doc.exists:
            return False
        doc_ref.delete()
        return True

    def update_ingredient(self, ingredient_id: str, ingredient_in: IngredientCreate, created_at: str) -> Ingredient:
        ingredient = Ingredient(
            id=ingredient_id,
            createdAt=created_at,
            **ingredient_in.model_dump()
        )
        doc_ref = self.db.collection(self.collection_name).document(ingredient_id)
        doc_ref.set(ingredient.model_dump())
        return ingredient


# Factory function to get configured database provider
_provider_instance: Optional[DatabaseProvider] = None

def get_db_provider() -> DatabaseProvider:
    global _provider_instance
    if _provider_instance is None:
        provider_name = os.getenv("DB_PROVIDER", "sqlite").lower()
        if provider_name == "firestore":
            _provider_instance = FirestoreProvider()
        else:
            db_path = os.getenv("DB_PATH", "food_waste.db")
            _provider_instance = SQLiteProvider(db_path)
    return _provider_instance
