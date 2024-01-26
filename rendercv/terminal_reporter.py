from rich import print


def warning(text):
    print(f"[bold yellow]⚠️:[/bold yellow] {text}")


def error(text):
    print(f"[bold red]❌:[/bold red] {text}")


def information(text):
    print(f"[bold cyan]ℹ️:[/bold cyan] {text}")
