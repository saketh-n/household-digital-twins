"""
Anthropic Vision Service
Uses Claude's vision capabilities to detect books in images
"""
import base64
import os
from typing import Optional
import anthropic
from pydantic import BaseModel


class DetectedBook(BaseModel):
    """Book detected from image analysis"""
    title: str
    author: str


class BookDetectionResult(BaseModel):
    """Result of book detection from an image"""
    books: list[DetectedBook]
    raw_response: Optional[str] = None


async def detect_books_in_image(
    image_data: bytes,
    media_type: str = "image/jpeg"
) -> BookDetectionResult:
    """
    Analyze an image using Claude's vision to detect books
    
    Args:
        image_data: Raw image bytes
        media_type: MIME type of the image (image/jpeg, image/png, image/gif, image/webp)
    
    Returns:
        BookDetectionResult with list of detected books
    """
    client = anthropic.Anthropic(
        api_key=os.getenv("ANTHROPIC_API_KEY")
    )
    
    # Encode image to base64
    base64_image = base64.standard_b64encode(image_data).decode("utf-8")
    
    # Create the prompt for book detection
    prompt = """Analyze this image of a bookshelf or books. 
    
Identify all visible books and extract their titles and authors.

Return your response as a JSON object with the following structure:
{
  "books": [
    {"title": "Book Title", "author": "Author Name"},
    ...
  ]
}

Important guidelines:
- Only include books where you can clearly read or confidently identify the title
- If you can see a title but not the author, make your best guess based on the book or use "Unknown" 
- If a book spine is partially visible or unclear, skip it
- Return ONLY the JSON object, no additional text or markdown formatting
- If no books are visible, return {"books": []}"""

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": media_type,
                            "data": base64_image,
                        },
                    },
                    {
                        "type": "text",
                        "text": prompt
                    }
                ],
            }
        ],
    )
    
    # Parse the response
    response_text = message.content[0].text
    
    # Try to parse as JSON
    import json
    try:
        # Handle case where response might have markdown code blocks
        cleaned_response = response_text.strip()
        if cleaned_response.startswith("```"):
            # Remove markdown code block formatting
            lines = cleaned_response.split("\n")
            cleaned_response = "\n".join(lines[1:-1])
        
        data = json.loads(cleaned_response)
        books = [
            DetectedBook(title=b["title"], author=b["author"])
            for b in data.get("books", [])
        ]
    except json.JSONDecodeError:
        # If parsing fails, return empty list with raw response for debugging
        books = []
    
    return BookDetectionResult(
        books=books,
        raw_response=response_text
    )

