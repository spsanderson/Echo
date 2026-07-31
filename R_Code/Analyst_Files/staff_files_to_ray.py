import os
import glob
import re
import datetime
import win32com.client as win32
import pypandoc
import subprocess

base_path = r"C:\Users\ssanders\Documents\GitHub\my_obsidian_vault\Work\Analyst_Team"
output_dir = r"C:\Users\ssanders\Documents\GitHub\my_obsidian_vault\Work\pdfs_for_ray"

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Get all subdirectories (equivalent to list.dirs(base_path)[-1L])
# We want immediate subdirectories
input_dirs = [os.path.join(base_path, d) for d in os.listdir(base_path) 
              if os.path.isdir(os.path.join(base_path, d))]

files_to_delete = glob.glob(os.path.join(output_dir, "*.pdf"))

if files_to_delete:
    print("Deleting old .pdf files...")
    for file_path in files_to_delete:
        try:
            os.remove(file_path)
        except OSError as e:
            print(f"Error deleting {file_path}: {e}")

for input_dir in input_dirs:
    if not os.path.exists(input_dir):
        print(f"Error: Directory {input_dir} does not exist.")
        continue

    print("\nSearching for .md files in:", input_dir)
    md_files = glob.glob(os.path.join(input_dir, "*.md"))

    if not md_files:
        print("No .md files found in the specified directory.")
        continue

    print(f"Found {len(md_files)} .md files:")
    for file in md_files:
        print(f"- {os.path.basename(file)}")

    print("\n")
    
    # Find newest file based on modification time
    newest_md = max(md_files, key=os.path.getmtime)
    print("The newest file is:", newest_md)
    print("With basename of:", os.path.basename(newest_md), "\n")

    print("Converting file to PDF File.\n")
    
    pdf_filename = re.sub(r'\.md$', '.pdf', os.path.basename(newest_md))
    print("New File: ", pdf_filename)
    pdf_filepath = os.path.join(output_dir, pdf_filename)
    
    with open(newest_md, 'r', encoding='utf-8') as f:
        md_text = f.read()
        
    # Replace the checkmark emoji with [OK] to avoid LaTeX unicode errors
    md_text = md_text.replace("✅", "[OK]")
    
    try:
        # Convert using pypandoc.convert_text instead of convert_file
        pypandoc.convert_text(
            source=md_text,
            to='pdf',
            format='md',
            outputfile=pdf_filepath
        )
        print("Successfully converted to PDF.\n")
    except Exception as e:
        error_msg = str(e)
        match = re.search(r"File `(.*?)'\.sty' not found", error_msg)
        
        if match:
            missing_pkg = match.group(1)
            print(f"Missing LaTeX package detected: {missing_pkg}")
            print(f"Attempting to install {missing_pkg} via tlmgr...")
            try:
                subprocess.run(["tlmgr", "install", missing_pkg], check=True)
                print(f"Successfully installed {missing_pkg}. Retrying conversion...")
                
                # Retry conversion after installing package
                pypandoc.convert_text(
                    source=md_text,
                    to='pdf',
                    format='md',
                    outputfile=pdf_filepath
                )
                print("Successfully converted to PDF.\n")
            except subprocess.CalledProcessError as sub_e:
                print(f"Failed to install package {missing_pkg}: {sub_e}\n")
        else:
            print(f"Error during conversion: {e}\n")

output_files = glob.glob(os.path.join(output_dir, "*.pdf"))

# The most Recent Monday from today
today = datetime.date.today()
# weekday() returns 0 for Monday, so we subtract weekday() days
last_monday = today - datetime.timedelta(days=today.weekday())

filtered_paths = []
date_pattern = re.compile(r'\d{4}-\d{2}-\d{2}')

print("Extracted dates:")
print(f"{'Date':<15} | {'Kept':<6} | {'File'}")
print("-" * 50)

for file_path in output_files:
    filename = os.path.basename(file_path)
    match = date_pattern.search(filename)
    
    if match:
        date_str = match.group(0)
        try:
            file_date = datetime.datetime.strptime(date_str, "%Y-%m-%d").date()
            kept = file_date >= last_monday
            
            print(f"{file_date} | {str(kept):<6} | {filename}")
            
            if kept:
                filtered_paths.append(file_path)
                
        except ValueError:
             print(f"Invalid date format found in file: {filename}")

print("\nFiltered file paths (date >= last_monday):")
for p in filtered_paths:
    print(p)

if filtered_paths:
    try:
        print("\nPreparing email...")
        outlook = win32.Dispatch('outlook.application')
        mail = outlook.CreateItem(0)
        
        mail.To = 'Raymond.Gross2@stonybrookmedicine.edu'
        mail.Subject = 'Weekly Staff Updates'
        mail.Body = """Hi Ray,
    
Please see attached files which are the latest files I have from my 1:1 with staff.
"""
        
        # Add attachments
        for file in filtered_paths:
            # Outlook requires absolute paths
            abs_path = os.path.abspath(file)
            mail.Attachments.Add(abs_path)
            
        # Use mail.Display() to open the draft, or mail.Send() to send it immediately
        mail.Send()
        print("Email sent successfully.")
        
    except Exception as e:
        print(f"Error sending email: {e}")
else:
    print("\nNo files met the date criteria. Email not sent.")