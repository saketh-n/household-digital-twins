# Household Digital Twins - Bookshelf

A full-stack application for creating a digital twin of your bookshelf using AI vision.

## Architecture

```
household-digital-twins/
├── ios-app/                    # iOS Swift frontend (Xcode project)
├── backend/                    # FastAPI Python backend
│   ├── main.py                 # API server
│   ├── models/                 # Data models
│   │   └── bookshelf.py        # Bookshelf digital twin
│   ├── services/               # External services
│   │   ├── anthropic_service.py    # Claude Vision integration
│   │   └── openlibrary_service.py  # Book cover fetching
│   └── data/
│       └── bookshelf.json      # Persisted bookshelf data
└── README.md
```

## Features

- **📸 Image Scanning**: Upload a photo of your bookshelf and AI will detect all visible books
- **📚 Book Detection**: Uses Claude's vision capabilities to identify book titles and authors
- **🖼️ Cover Fetching**: Automatically fetches book cover images from OpenLibrary
- **💾 Digital Twin**: Maintains a persistent model of your bookshelf
- **🔄 CRUD Operations**: Query, add, and remove books from your digital bookshelf

## Backend Setup

### Prerequisites

- Python 3.11+
- Anthropic API key

### Installation

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variable
export ANTHROPIC_API_KEY="your-api-key-here"
```

### Running the Server

```bash
# Development
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Production
uvicorn main:app --host 0.0.0.0 --port 8000
```

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check and config status |
| POST | `/scan` | Upload image to detect books |
| GET | `/bookshelf` | Get all books in bookshelf |
| POST | `/bookshelf/book` | Manually add a book |
| DELETE | `/bookshelf/book` | Remove a specific book |
| DELETE | `/bookshelf` | Clear all books |

### API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## iOS App Setup

The `ios-app/` directory is a placeholder for the iOS Swift frontend. 

To set up:
1. Open Xcode
2. Create a new iOS project in the `ios-app/` directory
3. Configure the app to communicate with the backend API

## Usage Flow

1. **Take a Photo**: iOS app captures image of bookshelf
2. **Upload**: Image sent to `/scan` endpoint
3. **AI Analysis**: Claude Vision detects books in image
4. **Enrichment**: OpenLibrary adds cover images
5. **Storage**: Books added to digital twin
6. **Display**: iOS app queries `/bookshelf` to show collection

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Your Anthropic API key for Claude Vision |

## Example Requests

### Scan a Bookshelf Image

```bash
curl -X POST "http://localhost:8000/scan" \
  -H "Content-Type: multipart/form-data" \
  -F "image=@bookshelf.jpg"
```

### Get Bookshelf

```bash
curl "http://localhost:8000/bookshelf"
```

### Add a Book Manually

```bash
curl -X POST "http://localhost:8000/bookshelf/book" \
  -H "Content-Type: application/json" \
  -d '{"title": "1984", "author": "George Orwell"}'
```

## License

MIT

