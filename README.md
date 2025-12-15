# 🎬 Personalized Movie Recommendation System

This project delivers a comprehensive movie recommendation system, featuring a robust Python-based machine learning backend powered by FastAPI and a dynamic cross-platform mobile application developed with Flutter. It's designed to offer users a personalized movie discovery experience by leveraging advanced machine learning models to understand and predict their preferences.

## 📝 Table of Contents

- [🚀 Tech Stack](#-tech-stack)
- [✨ Key Features](#-key-features)
- [🧠 How the Code Works](#-how-the-code-works)
- [📂 Folder Structure](#-folder-structure)
- [⚙️ Installation](#️-installation)
- [💡 Usage Examples](#-usage-examples)

## 🚀 Tech Stack

The project is built using a modern and efficient technology stack to ensure performance, scalability, and a rich user experience.

### Backend
- **FastAPI** ![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white) - Modern Python web framework for building APIs
- **Python** ![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
- **MySQL** ![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white) - Relational database for storing user data, movies, and ratings
- **Machine Learning**:
  - **XGBoost** ![XGBoost](https://img.shields.io/badge/XGBoost-0083B3?style=for-the-badge&logo=xgboost&logoColor=white)
  - **Scikit-learn** ![Scikit-learn](https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white) - KMeans clustering and ML utilities

### Frontend
- **Flutter** ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
- **Dart** ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
- **SQLite** - Local database for offline data storage

## ✨ Key Features

The application provides a rich set of features designed to enhance movie discovery and user engagement:

- **Personalized Recommendations**: The system intelligently recommends movies by clustering users based on their training data and genre preferences.
- **Movie Similarity**: Discover movies similar to ones you enjoy, leveraging advanced similarity metrics.
- **Rating Prediction**: Predict future movie ratings for users, helping them decide what to watch next.
- **Like/Dislike Prediction**: Utilizes an XGBoost classifier to predict whether a user will like or dislike a specific movie.
- **User Authentication**: Secure login and sign-up functionalities for personalized experiences.
- **Genre Selection**: Allows users to select and manage their preferred movie genres.
- **Comprehensive Movie Details**: Dedicated screens providing detailed information about each movie.
- **Efficient Search Functionality**: Easily find movies by title or other criteria.
- **User Profile Management**: Manage user profiles and preferences within the app.
- **Engaging UI Components**: Features interactive elements like featured banners, movie cards, and carousels for a visually appealing experience.
- **Cross-Platform Accessibility**: A single codebase delivers the mobile application across Android, iOS, Web, and desktop platforms.

## 🧠 How the Code Works

### Backend Overview

The backend directory houses the machine learning models and the FastAPI logic.

- **main.py** is the primary entry point for the FastAPI backend, serving API endpoints for recommendations.
- **ratings.dat** is a core dataset used for training and evaluating recommendation models.
- **test_model_api.py** is dedicated to testing the functionalities exposed by the recommendation models.
- The **models/** directory stores various pre-trained machine learning models:
  - `kmeans_model_cluster_users_based_on_their_training.pkl` and `users_with_same_genres_preferences_cluster.pkl` are K-Means clustering models used to group users with similar viewing habits and genre preferences.
  - `similarity_matrix.pkl` and `movies_for_similarity.pkl` are used to calculate and retrieve similar movies based on their characteristics.
  - `xgb_classifier_predicting_like_vs_dislike_model.pkl` is an XGBoost classifier for predicting binary user preferences (like/dislike).
  - `xgb_predicting_future_movie_ratings_model.pkl` is an XGBoost model developed to predict numerical future ratings for movies.
  - `cluster_sim.pkl` and `xgb_model.pkl` likely represent other intermediate or generalized model artifacts.
  - `data.pkl` stores processed data necessary for the models to function.

### Frontend Overview

The frontend directory contains the Flutter mobile application, designed for cross-platform deployment.

- **main.dart** is the main Dart file that bootstraps the Flutter application.
- The **assets/** folder stores local data files such as `movies.dat`, `ratings.dat`, and `users.dat`, which might be used for initial data loading or offline capabilities.
- **lib/database/db_helper.dart** manages local database operations using SQLite, ensuring persistent storage for user data or application state.
- **lib/models/movie.dart** and **lib/models/user.dart** define the data structures for movies and users, ensuring consistent data handling throughout the application.
- The **lib/screens/** directory organizes the various user interface screens:
  - `splash_screen.dart` and `onboarding_screen.dart` handle the initial app launch and guided introduction.
  - `login_screen.dart` and `sign_up_screen.dart` facilitate user authentication.
  - `select_genres_screen.dart` allows users to specify their movie preferences.
  - `home_screen.dart` is the central hub for discovering recommended movies.
  - `movie_details_screen.dart` displays comprehensive information about a selected movie.
  - `search_screen.dart`, `profile_screen.dart`, and `settings_screen.dart` provide search, user management, and application configuration functionalities, respectively.
- **lib/services/api_service.dart** handles communication with the FastAPI backend to fetch recommendations and other data.
- **lib/services/data_loader.dart** is responsible for loading and preparing data for the application, while **lib/services/fetch_posters.dart** manages fetching movie poster images, likely from an external media API.
- **lib/themes/app_theme.dart** defines the application's overall visual style, including colors and typography.
- The **lib/widgets/** directory contains reusable UI components such as `featured_banner.dart`, `movie_card.dart`, and `movie_carousel.dart` to build dynamic and interactive interfaces.

## 📂 Folder Structure
```
./
├── backend/
│   ├── main.py
│   ├── ratings.dat
│   ├── test_model_api.py
│   └── models/
│       ├── cluster_sim.pkl
│       ├── data.pkl
│       ├── kmeans_model_cluster_users_based_on_their_training.pkl
│       ├── movies_for_similarity.pkl
│       ├── similarity_matrix.pkl
│       ├── users_with_same_genres_preferences_cluster.pkl
│       ├── xgb_classifier_predicting_like_vs_dislike_model.pkl
│       ├── xgb_model.pkl
│       └── xgb_predicting_future_movie_ratings_model.pkl
└── frontend/
    ├── assets/
    │   ├── movies.dat
    │   ├── ratings.dat
    │   └── users.dat
    ├── lib/
    │   ├── main.dart
    │   ├── database/
    │   │   └── db_helper.dart
    │   ├── models/
    │   │   ├── movie.dart
    │   │   └── user.dart
    │   ├── screens/
    │   │   ├── home_screen.dart
    │   │   ├── login_screen.dart
    │   │   ├── movie_details_screen.dart
    │   │   ├── onboarding_screen.dart
    │   │   ├── profile_screen.dart
    │   │   ├── search_screen.dart
    │   │   ├── select_genres_screen.dart
    │   │   ├── settings_screen.dart
    │   │   ├── sign_up_screen.dart
    │   │   └── splash_screen.dart
    │   ├── services/
    │   │   ├── api_service.dart
    │   │   ├── data_loader.dart
    │   │   └── fetch_posters.dart
    │   ├── themes/
    │   │   └── app_theme.dart
    │   └── widgets/
    │       ├── featured_banner.dart
    │       ├── movie_card.dart
    │       └── movie_carousel.dart
    ├── android/
    ├── ios/
    ├── web/
    ├── linux/
    ├── macos/
    ├── windows/
    ├── test/
    └── pubspec.yaml
```

## ⚙️ Installation

### Prerequisites

Before you begin, ensure you have the following installed:

- **Python 3.8+** - [Download Python](https://www.python.org/downloads/)
- **MySQL 8.0+** - [Download MySQL](https://dev.mysql.com/downloads/)
- **Flutter SDK 3.0+** - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Git** - [Download Git](https://git-scm.com/downloads)

### 1. Clone the Repository
```bash
git clone https://github.com/haythem-abdellaoui/Application-Mobile-Intelligente-de-Recommandation-des-Films.git
cd Application-Mobile-Intelligente-de-Recommandation-des-Films
```

### 2. MySQL Database Setup

#### Install MySQL

If you haven't installed MySQL, download and install it from the [official website](https://dev.mysql.com/downloads/mysql/).

#### Setup Database with phpMyAdmin

1. **Start your local server** (XAMPP, WAMP, or MAMP)
2. **Open phpMyAdmin** in your browser: `http://localhost/phpmyadmin`
3. **Create a new database**:
   - Click on "New" in the left sidebar
   - Database name: `movie_recommendation_db`
   - Collation: `utf8mb4_general_ci`
   - Click "Create"
4. **Import the SQL file**:
   - Select the `movie_recommendation_db` database from the left sidebar
   - Click on the "Import" tab at the top
   - Click "Choose File" and select `movies_mobile(4).sql`
   - Scroll down and click "Import"
   - Wait for the import to complete successfully

**Note**: Make sure your `movies_mobile(4).sql` file is ready before importing. The file should contain all necessary tables (users, movies, ratings, user_preferences) and initial data.

### 3. Backend Setup (FastAPI)
```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install fastapi uvicorn mysql-connector-python sqlalchemy pydantic python-multipart bcrypt python-jose pandas numpy scikit-learn xgboost pickle-mixin

# Create .env file for configuration
cat > .env << EOL
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_NAME=movie_recommendation_db
DATABASE_USER=root
DATABASE_PASSWORD=your_mysql_password

SECRET_KEY=your_secret_key_here_change_this
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOL

# Run the FastAPI server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The backend API will be available at `http://localhost:8000`

### 4. Frontend Setup (Flutter)
```bash
# Navigate to frontend directory
cd ../frontend

# Install Flutter dependencies
flutter pub get

# Configure API endpoint
# Edit lib/services/api_service.dart and update the base URL to point to your backend
# Example: static const String baseUrl = 'http://localhost:8000';

# Check Flutter installation
flutter doctor

# Run the app on your preferred platform
# For Android emulator/device:
flutter run

# For iOS simulator (macOS only):
flutter run -d ios

# For Web:
flutter run -d chrome

# For Desktop (Windows):
flutter run -d windows

# For Desktop (macOS):
flutter run -d macos

# For Desktop (Linux):
flutter run -d linux
```

### 5. Load Initial Data (Optional)

If you have initial movie data in the `.dat` files:
```bash
# Create a Python script to load data into MySQL
cd backend

# Run data migration script (create this script based on your data format)
python load_data.py
```

## 🔧 Configuration

### Backend API Configuration

Edit the `.env` file in the `backend/` directory:
```env
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_NAME=movie_recommendation_db
DATABASE_USER=root
DATABASE_PASSWORD=your_password

SECRET_KEY=generate_a_secure_random_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### Frontend API Configuration

Edit `lib/services/api_service.dart`:
```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Change to your server URL
  // For Android emulator use: 'http://10.0.2.2:8000'
  // For physical device use your computer's IP: 'http://192.168.x.x:8000'
}
```

## 📡 API Endpoints

The FastAPI backend provides the following endpoints:

### Authentication
- `POST /api/auth/signup` - Register new user
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user info

### Movies
- `GET /api/movies` - Get all movies
- `GET /api/movies/{movie_id}` - Get movie details
- `GET /api/movies/search` - Search movies

### Recommendations
- `GET /api/recommendations/{user_id}` - Get personalized recommendations
- `GET /api/recommendations/similar/{movie_id}` - Get similar movies

### Ratings
- `POST /api/ratings` - Submit movie rating
- `GET /api/ratings/{user_id}` - Get user ratings
- `PUT /api/ratings/{rating_id}` - Update rating

### Predictions
- `POST /api/predict/rating` - Predict movie rating for user
- `POST /api/predict/like` - Predict like/dislike for user

## 💡 Usage Examples

The mobile application guides users through a seamless movie discovery journey:

1. **Splash & Onboarding**: Users are greeted with a splash screen followed by an onboarding experience to introduce key features.
2. **Authentication**: Users can sign up for a new account or log in to an existing one.
3. **Genre Selection**: New users, or those updating preferences, can select their favorite movie genres, which helps in tailoring recommendations.
4. **Home Screen**: Upon logging in, users land on the home screen, displaying a personalized feed of recommended movies, featured banners, and various movie carousels.
5. **Movie Details**: Tapping on a movie card leads to a detailed screen with information about the selected movie.
6. **Rating Movies**: Users can rate movies they've watched, which improves the recommendation algorithm.
7. **Search**: Users can search for specific movies using the search functionality.
8. **Profile & Settings**: Users can access their profile to view or edit details, and adjust application settings.

## 🧪 Testing

### Test Backend API
```bash
cd backend
python test_model_api.py
```

### Test Flutter App
```bash
cd frontend
flutter test
```

## 📱 Building for Production

### Android APK
```bash
cd frontend
flutter build apk --release
```

The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

### iOS App
```bash
cd frontend
flutter build ios --release
```

### Web Application
```bash
cd frontend
flutter build web
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

**Haythem Abdellaoui**
- GitHub: [@haythem-abdellaoui](https://github.com/haythem-abdellaoui)

---

⭐ If you found this project helpful, please give it a star!
