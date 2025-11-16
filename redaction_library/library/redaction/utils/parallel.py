"""Parallel processing utility for concurrent redaction operations."""
import asyncio
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor, as_completed
from typing import List, Callable, Any, Optional, Literal
import multiprocessing


class ParallelProcessor:
    """
    Handle parallel processing of redaction tasks.

    Uses ProcessPool for CPU-bound tasks (redaction) and ThreadPool for I/O-bound tasks (API calls).
    """

    def __init__(self, max_workers: Optional[int] = None):
        """
        Initialize the parallel processor.

        Args:
            max_workers: Maximum number of workers (defaults to CPU count)
        """
        self.max_workers = max_workers or multiprocessing.cpu_count()

    def process_parallel(self,
                        func: Callable,
                        items: List[Any],
                        task_type: Literal['cpu', 'io'] = 'cpu',
                        *args,
                        **kwargs) -> List[Any]:
        """
        Process items in parallel using the appropriate executor.

        Args:
            func: Function to apply to each item
            items: List of items to process
            task_type: 'cpu' for CPU-bound (uses ProcessPool), 'io' for I/O-bound (uses ThreadPool)
            *args: Additional positional arguments to pass to func
            **kwargs: Additional keyword arguments to pass to func

        Returns:
            List of results in the same order as items
        """
        if not items:
            return []

        # Choose executor based on task type
        # CPU-bound: ProcessPool for true parallelism (bypasses GIL)
        # I/O-bound: ThreadPool for lightweight concurrency (GIL released during I/O)
        executor_class = ProcessPoolExecutor if task_type == 'cpu' else ThreadPoolExecutor

        with executor_class(max_workers=self.max_workers) as executor:
            # Submit all tasks
            future_to_index = {
                executor.submit(func, item, *args, **kwargs): i
                for i, item in enumerate(items)
            }

            # Collect results in order
            results = [None] * len(items)
            for future in as_completed(future_to_index):
                index = future_to_index[future]
                try:
                    results[index] = future.result()
                except Exception as e:
                    # Store the exception as the result
                    results[index] = e

        return results

    async def process_async(self,
                           func: Callable,
                           items: List[Any],
                           *args,
                           **kwargs) -> List[Any]:
        """
        Process items asynchronously.

        Args:
            func: Async function to apply to each item
            items: List of items to process
            *args: Additional positional arguments to pass to func
            **kwargs: Additional keyword arguments to pass to func

        Returns:
            List of results in the same order as items
        """
        if not items:
            return []

        # Create tasks for all items
        tasks = [func(item, *args, **kwargs) for item in items]

        # Run all tasks concurrently
        results = await asyncio.gather(*tasks, return_exceptions=True)

        return list(results)

    async def process_async_batched(self,
                                    func: Callable,
                                    items: List[Any],
                                    batch_size: int = 10,
                                    *args,
                                    **kwargs) -> List[Any]:
        """
        Process items asynchronously in batches to control concurrency.

        Args:
            func: Async function to apply to each item
            items: List of items to process
            batch_size: Number of items to process concurrently
            *args: Additional positional arguments to pass to func
            **kwargs: Additional keyword arguments to pass to func

        Returns:
            List of results in the same order as items
        """
        if not items:
            return []

        results = []

        # Process in batches
        for i in range(0, len(items), batch_size):
            batch = items[i:i + batch_size]
            batch_tasks = [func(item, *args, **kwargs) for item in batch]
            batch_results = await asyncio.gather(*batch_tasks, return_exceptions=True)
            results.extend(batch_results)

        return results

    def process_chunks_parallel(self,
                               func: Callable,
                               chunks: List[tuple],
                               *args,
                               **kwargs) -> List[Any]:
        """
        Process text chunks in parallel using ProcessPool (CPU-bound).

        Args:
            func: Function to apply to each chunk (chunk_text, start_position)
            chunks: List of (chunk_text, start_position) tuples
            *args: Additional positional arguments to pass to func
            **kwargs: Additional keyword arguments to pass to func

        Returns:
            List of (result, start_position) tuples
        """
        if not chunks:
            return []

        def process_chunk(chunk_tuple):
            chunk_text, start_pos = chunk_tuple
            result = func(chunk_text, start_pos, *args, **kwargs)
            return (result, start_pos)

        # Use ProcessPool for CPU-bound redaction work
        with ProcessPoolExecutor(max_workers=self.max_workers) as executor:
            future_to_index = {
                executor.submit(process_chunk, chunk): i
                for i, chunk in enumerate(chunks)
            }

            results = [None] * len(chunks)
            for future in as_completed(future_to_index):
                index = future_to_index[future]
                try:
                    results[index] = future.result()
                except Exception as e:
                    results[index] = (e, chunks[index][1])

        return results

    async def process_chunks_async(self,
                                  func: Callable,
                                  chunks: List[tuple],
                                  *args,
                                  **kwargs) -> List[Any]:
        """
        Process text chunks asynchronously.

        Args:
            func: Async function to apply to each chunk
            chunks: List of (chunk_text, start_position) tuples
            *args: Additional positional arguments to pass to func
            **kwargs: Additional keyword arguments to pass to func

        Returns:
            List of (result, start_position) tuples
        """
        if not chunks:
            return []

        async def process_chunk(chunk_tuple):
            chunk_text, start_pos = chunk_tuple
            result = await func(chunk_text, start_pos, *args, **kwargs)
            return (result, start_pos)

        tasks = [process_chunk(chunk) for chunk in chunks]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        return list(results)
