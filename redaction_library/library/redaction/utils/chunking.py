"""Text chunking utility for handling large text."""
from typing import List, Tuple


class TextChunker:
    """Handle chunking of large text for efficient processing."""

    def __init__(self, chunk_size: int = 5000, overlap: int = 0):
        """
        Initialize the text chunker.

        Args:
            chunk_size: Maximum size of each chunk in characters (default: 5000)
            overlap: Number of characters to overlap between chunks (default: 0 - no overlap)
        """
        self.chunk_size = chunk_size
        self.overlap = overlap

    def chunk_text(self, text: str) -> List[Tuple[str, int]]:
        """
        Split text into chunks based on word boundaries.

        Args:
            text: The text to chunk

        Returns:
            List of tuples (chunk_text, start_position)
        """
        if len(text) <= self.chunk_size:
            return [(text, 0)]

        chunks = []
        start = 0

        while start < len(text):
            # Calculate end position
            end = min(start + self.chunk_size, len(text))

            # If not at the end, break at word boundary
            if end < len(text):
                # Find the last space before the chunk_size limit
                last_space = text.rfind(' ', start, end)
                if last_space > start:
                    end = last_space + 1  # Include the space

            chunk = text[start:end]
            chunks.append((chunk, start))

            # Move start position (no overlap)
            start = end

        return chunks

    def merge_results(self, chunk_results: List[Tuple[str, int, List]]) -> Tuple[str, List]:
        """
        Merge redacted chunks back together (no overlap handling needed).

        Args:
            chunk_results: List of (redacted_chunk, start_position, tokens)

        Returns:
            Tuple of (merged_text, all_tokens)
        """
        if not chunk_results:
            return "", []

        if len(chunk_results) == 1:
            return chunk_results[0][0], chunk_results[0][2]

        # Simple concatenation since there's no overlap
        merged_text = ""
        all_tokens = []

        for chunk_text, start_pos, tokens in chunk_results:
            merged_text += chunk_text
            all_tokens.extend(tokens)

        return merged_text, all_tokens

    def estimate_chunks(self, text_length: int) -> int:
        """
        Estimate the number of chunks for a given text length.

        Args:
            text_length: Length of the text

        Returns:
            Estimated number of chunks
        """
        if text_length <= self.chunk_size:
            return 1

        return (text_length + self.chunk_size - 1) // self.chunk_size
