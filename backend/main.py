from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from joblib import load
from typing import List, Dict, Optional
import mysql.connector

app = FastAPI()

genre_cluster_model = load("models/users_with_same_genres_preferences_cluster.pkl")
print(">>> RUNNING main.py <<<")

class UserGenres(BaseModel):
    user_id: str
    preferred_genres: list[int]

@app.post("/cluster")
def test_genre_cluster(user: UserGenres):
    g = user.preferred_genres
    if len(g) < 7:
        raise HTTPException(status_code=422, detail="preferred_genres must have at least 7 elements")
    try:
        merged_features = [
            g[2] | g[3],
            g[2] | g[4],
        ]
        cluster_label = genre_cluster_model.predict([merged_features])[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"user_id": user.user_id, "cluster": int(cluster_label)}


# sending data to mysql

class Movie(BaseModel):
    id: str
    title: str
    genres: Optional[str] = None
    rating: Optional[float] = None
    year: Optional[int] = None
    description: Optional[str] = None
    posterUrl: Optional[str] = None

class User(BaseModel):
    userId: str
    username: str
    password: str
    gender: Optional[str] = None
    age: Optional[int] = None
    occupation: Optional[int] = None
    zipCode: Optional[str] = None
    preferred_genres: Optional[str] = None  

class DataPayload(BaseModel):
    movies: List[Movie]
    users: List[User]

# upload data to mysql
@app.post("/upload-sqlite-data")
def upload_sqlite_data(payload: DataPayload):
    try:
        # Connect to MySQL
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="movies_mobile"
        )
        cursor = conn.cursor()

        # Insert movies
        for movie in payload.movies:
            cursor.execute(
                """INSERT INTO movies (id, title, genres, rating, year, description, posterUrl)
                   VALUES (%s, %s, %s, %s, %s, %s, %s)
                   ON DUPLICATE KEY UPDATE title=VALUES(title)""",
                (movie.id, movie.title, movie.genres, movie.rating, movie.year, movie.description, movie.posterUrl)
            )

        # Insert users
        for user in payload.users:
            cursor.execute(
                """INSERT INTO users (userId, username, password, gender, age, occupation, zipCode, preferred_genres)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                   ON DUPLICATE KEY UPDATE
                       username=VALUES(username),
                       password=VALUES(password),
                       gender=VALUES(gender),
                       age=VALUES(age),
                       occupation=VALUES(occupation),
                       zipCode=VALUES(zipCode),
                       preferred_genres=VALUES(preferred_genres)""",
                (
                    user.userId,
                    user.username,
                    user.password,
                    user.gender if user.gender is not None else None,
                    user.age if user.age is not None else None,
                    user.occupation if user.occupation is not None else None,
                    user.zipCode if user.zipCode is not None else None,
                    user.preferred_genres if user.preferred_genres is not None else None
                )
            )

        conn.commit()
        cursor.close()
        conn.close()

        return {
            "status": "success",
            "movies_inserted": len(payload.movies),
            "users_inserted": len(payload.users)
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# add user
@app.post("/add-user")
def add_user(user: User):
    # Generate userId if missing
    user_id = user.userId or str(int(time.time() * 1000))
    
    # Insert into MySQL
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="movies_mobile"
    )
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO users (userId, username, password, gender, age, occupation, zipCode, preferred_genres)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            username=VALUES(username),
            password=VALUES(password),
            gender=VALUES(gender),
            age=VALUES(age),
            occupation=VALUES(occupation),
            zipCode=VALUES(zipCode),
            preferred_genres=VALUES(preferred_genres)
        """,
        (
            user_id,
            user.username,
            user.password,
            user.gender,
            user.age,
            user.occupation,
            user.zipCode,
            user.preferred_genres
        )
    )
    conn.commit()
    cursor.close()
    conn.close()

    return {"status": "success", "userId": user_id}