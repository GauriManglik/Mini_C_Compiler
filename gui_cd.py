import subprocess
import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext, font

# WSL paths
WSL_DIR = ""
TEMP_C_FILE = f"{WSL_DIR}/temp.c"

def save_code_to_wsl(code: str) -> bool:
    try:
        # Escape double quotes for bash echo
        safe_code = code.replace('"', '\\"')
        bash_command = f'echo "{safe_code}" > "{TEMP_C_FILE}"'
        subprocess.run(["wsl", "bash", "-c", bash_command], check=True)
        return True
    except subprocess.CalledProcessError as e:
        messagebox.showerror("Error", f"Could not write file in WSL:\n{e}")
        return False

def run_compiler():
    code = text_input.get("1.0", tk.END).strip()
    if not code:
        messagebox.showwarning("Warning", "Please enter some C code.")
        return

    if not save_code_to_wsl(code):
        return

    try:
        command = f'cd "{WSL_DIR}" && ./mini_compiler "{TEMP_C_FILE}"'
        result = subprocess.run(["wsl", "bash", "-c", command], capture_output=True, text=True)

        output_text = result.stdout + ("\nErrors:\n" + result.stderr if result.stderr else "")

        # Parse the output and update tables
        lexemes, symbol_table, intermediate_code = parse_output(output_text)
        update_tables(lexemes, symbol_table, intermediate_code)

    except Exception as e:
        messagebox.showerror("Error", f"Failed to run compiler:\n{e}")

def parse_output(output, preprocessor_lines=None):
    lexemes = []
    symbol_table = []
    intermediate_code = []

    lines = output.splitlines()

    in_symbol_table = False
    in_intermediate_code = False

    for line in lines:
        line = line.strip()

        # Handle Token lines
        if line.startswith("Token:"):
            parts = line.split("Lexeme:")
            if len(parts) == 2:
                token_part = parts[0].strip()
                lexeme_part = parts[1].strip()
                token_num = token_part.split()[1]
                lexemes.append((token_num, lexeme_part))

        # Handle preprocessor directive parsing line
        elif line.startswith("Parsed preprocessor directive:"):
            directive = line.split("Parsed preprocessor directive:")[1].strip()
            lexemes.append(("Preprocessor", directive))  # Add as a special type

        # Handle Symbol Table section
        elif line == "Symbol Table:":
            in_symbol_table = True
            in_intermediate_code = False
            continue
        elif line == "Intermediate Code:":
            in_symbol_table = False
            in_intermediate_code = True
            continue

        elif in_symbol_table:
            if line and not line.startswith("-") and not line.startswith("Name"):
                parts = line.split()
                if len(parts) >= 3:
                    name, type_, value = parts[0], parts[1], parts[2]
                    symbol_table.append((name, type_, value))

        elif in_intermediate_code:
            if line:
                intermediate_code.append((line,))

    return lexemes, symbol_table, intermediate_code

def create_table(parent, columns, heading):
    frame = tk.Frame(parent)
    label = tk.Label(frame, text=heading, font=("Consolas", 14, "bold"))
    label.pack(anchor="w", padx=5, pady=(5, 0))

    tree = ttk.Treeview(frame, columns=columns, show="headings", height=25)
    tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(5,0), pady=5)

    for col in columns:
        tree.heading(col, text=col)
        tree.column(col, anchor=tk.CENTER, width=150)

    scrollbar = ttk.Scrollbar(frame, orient=tk.VERTICAL, command=tree.yview)
    tree.configure(yscroll=scrollbar.set)
    scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

    return frame, tree

def update_tables(lexemes, symbol_table, intermediate_code):
    # Clear old data
    for tree in (lex_tree, sym_tree, inter_tree):
        tree.delete(*tree.get_children())

    # Insert new data
    for row in lexemes:
        lex_tree.insert("", tk.END, values=row)
    for row in symbol_table:
        sym_tree.insert("", tk.END, values=row)
    for row in intermediate_code:
        inter_tree.insert("", tk.END, values=row)

# --- GUI Setup ---

root = tk.Tk()
root.title("Mini Compiler GUI with Tables")
root.geometry("1200x800")
root.configure(bg="#2e3440")

default_font = font.nametofont("TkDefaultFont")
default_font.configure(size=11, family="Consolas")

header_font = ("Consolas", 14, "bold")
label_fg = "#d8dee9"
bg_color = "#3b4252"
btn_color = "#81a1c1"
btn_fg = "#2e3440"

# Input Frame
input_frame = tk.Frame(root, bg=bg_color, bd=2, relief=tk.GROOVE, padx=10, pady=10)
input_frame.pack(fill=tk.X, padx=15, pady=(15,5))

tk.Label(input_frame, text="Paste your C code below:", bg=bg_color, fg=label_fg, font=header_font).pack(anchor="w")

text_input = scrolledtext.ScrolledText(input_frame, width=100, height=12, font=("Consolas", 11), wrap=tk.NONE)
text_input.pack(pady=10, fill=tk.X)

btn_run = tk.Button(
    input_frame,
    text="Run Compiler",
    command=run_compiler,
    bg=btn_color,
    fg=btn_fg,
    font=("Consolas", 12, "bold"),
    relief=tk.RAISED,
    activebackground="#5e81ac",
    activeforeground=btn_fg,
    padx=15,
    pady=7
)
btn_run.pack(pady=(0, 10))

# Output Frame for tables
output_frame = tk.Frame(root, bg=bg_color)
output_frame.pack(fill=tk.BOTH, expand=True, padx=15, pady=(5,15))

# Create 3 tables side by side
lex_frame, lex_tree = create_table(output_frame, ("Token", "Lexeme"), "Lexemes")
lex_frame.grid(row=0, column=0, sticky="nsew", padx=5)

sym_frame, sym_tree = create_table(output_frame, ("Name", "Type", "Value"), "Symbol Table")
sym_frame.grid(row=0, column=1, sticky="nsew", padx=5)

inter_frame, inter_tree = create_table(output_frame, ("Intermediate Code",), "Intermediate Code")
inter_frame.grid(row=0, column=2, sticky="nsew", padx=5)

output_frame.grid_columnconfigure(0, weight=1)
output_frame.grid_columnconfigure(1, weight=1)
output_frame.grid_columnconfigure(2, weight=1)
output_frame.grid_rowconfigure(0, weight=1)

# Color configurations for input box
text_input.config(bg="#eceff4", fg="#2e3440", insertbackground="#2e3440")

root.mainloop()
