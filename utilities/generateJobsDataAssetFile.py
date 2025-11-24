import json
import re
import threading
import tkinter as tk
from tkinter import filedialog as fd

# Imports to install
# > pip install pandas requests bs4 openpyxl
import pandas as pd
import requests
from bs4 import BeautifulSoup

# Constants
JSON_FILE_PATH = "assets/jobs-data.json"

EXCEL_SECTOR_HEADER = "N° secteur"
EXCEL_SPECIALIZATION_HEADER = "N° métiers"
EXCEL_SKILL_HEADER = "Numéro de compétences"

IS_OPTIONAL_REGEX = re.compile(r"images/ico_opt.gif")

# Data to change
EXCEL_SST_RISKS_HEADERS = {
    # json : excel
    "c": "1. Risques Chimiques",
    "b": "2. Risques Biologiques",
    "e": "3. Risques liés aux machines et aux équipements",
    "f": "4. Risques de chutes de hauteur et de plain-pied",
    "of": "5. Risques liés aux chutes d’objets",
    "t": " 6. Risques liés aux déplacements",
    "p": " 7. Risques liés aux postures contraignantes",
    "mv": "8. Risques liés aux mouvements répétitifs, pressions de contact et chocs",
    "h": "9. Risques liés à la manutention",
    "psy": "10. Risques psychosociaux et de violence",
    "n": "11. Risques liés au bruit",
    "et": "12. Risques liés à l'Froid et chaleur",
    "v": "13. Risques liés aux vibrations",
    "el": "14.1 Risques électriques",
    "a": "14.2 Risque anoxie et travail en espace clos",
    "fi": "14.3 Risque ATEX,  incendie ou explosion",
    "nm": "14.4 Risques nanomatériaux ",
}

EXCEL_STAGE_QUESTIONS_HEADERS = {
    # json : excel
    "1": "Q1",
    "2": "Q2",
    "3": "Q3",
    "4": "Q4",
    "5": "Q5",
    "6": "Q6",
    "7": "Q7",
    "8": "Q8",
    "9": "Q9",
    "10": "Q10",
    "11": "Q11",
    "12": "Q12",
    "13": "Q13",
    "14": "Q14",
    "15": "Q15",
    "16": "Q16",
    "17": "Q17",
    # "18": "Q18",  # This question has been removed from the app
}


# Main functions
def run():
    """Run the main script in a new thread"""

    def target():
        ui = [entrySSTRisks, entryStageQuestions, fileButtonSSTRisks, fileButtonStageQuestions, startButton]
        # Disable the UI
        for element in ui:
            element["state"] = "disabled"
        # Run the script
        start(excelPathSSTRisks.get(), excelPathStageQuestions.get())
        # Enable the UI
        for element in ui:
            element["state"] = "normal"

    threading.Thread(target=target).start()


def start(excelPathSSTRisks: str, excelPathStageQuestions: str):
    """Starts the main script"""
    # Open excel
    try:
        print(excelPathSSTRisks)
        excelSSTRisks = pd.read_excel(excelPathSSTRisks)
    except FileNotFoundError:
        setMessage("Could not read the SST excel file.")
        return

    try:
        excelStageQuestions = pd.read_excel(excelPathStageQuestions)
    except FileNotFoundError:
        setMessage("Could not read the Stage excel file.")
        return

    json = []
    for sectorID, sectorName in fetchActivitySectors():
        specializations = []
        for specializationURL in fetchSpecializationURLsOfSector(sectorID):
            specialization = fetchSpecialization(specializationURL)
            specializations.append(specialization)
            if specialization is None:
                continue

            try:
                specialization["q"] = getStageQuestionsFromExcel(excelStageQuestions, sectorID, specialization["id"])
            except KeyError as e:
                setMessage(
                    f"Stage Questions Excel Key Error : {e}. This usually means the selected excel file doesn't have valid headers."
                )
                return

            try:
                for skill in specialization["s"]:
                    skill["r"] = getSSTRisksFromExcel(excelSSTRisks, sectorID, specialization["id"], skill["id"])
            except KeyError as e:
                setMessage(
                    f"SST Risks Excel Key Error : {e}. This usually means the selected excel file doesn't have valid headers."
                )
                return

        json.append(
            {
                "n": sectorName,
                "id": sectorID,
                "s": specializations,
            }
        )

    saveJson(json, JSON_FILE_PATH)
    setMessage("All done !")


# Excel readers
def getSSTRisksFromExcel(excel: pd.DataFrame, sectorID: str, specializationID: str, skillID: str):
    """Returns the corresponding data contained in the SST Risks excel file"""
    result = []
    # Get the rows with the corresponding ids
    row = excel.loc[
        (excel[EXCEL_SECTOR_HEADER] == int(sectorID))
        & (excel[EXCEL_SPECIALIZATION_HEADER] == int(specializationID))
        & (excel[EXCEL_SKILL_HEADER] == int(skillID))
    ]

    # Iterate on the columns
    for name, excelHeader in EXCEL_SST_RISKS_HEADERS.items():
        if row[excelHeader].index.size == 0:
            # No data
            setMessage(
                f"Missing data ! This skill wasn't found in the excel SST Risks file. (sector: {sectorID}, specialization: {specializationID}, skill: {skillID})"
            )
            break
        elif row[excelHeader].index.size > 1:
            # Too much data
            setMessage(
                f"Too much data ! This skill was found more than once in the excel SST Risks file. (sector: {sectorID}, specialization: {specializationID}, skill: {skillID})"
            )
            break
        elif row[excelHeader].get(row[excelHeader].index[0], None) == None:
            # The cell is empty. This will probably never be true because of the first two if
            setMessage(
                f"Missing data ! This cell was empty in the excel SST Risks file. (sector: {sectorID}, specialization: {specializationID}, skill: {skillID}, risk: {excelHeader})"
            )
        elif row[excelHeader].get(row[excelHeader].index[0], "").strip().lower() == "oui":
            # Good data and data is "Oui"
            result.append(name)

    return result


def getStageQuestionsFromExcel(excel: pd.DataFrame, sectorID: str, specializationID: str):
    """Returns the corresponding data contained in the stage Questions excel file"""
    result = []
    # Get the rows with the corresponding ids
    row = excel.loc[
        (excel[EXCEL_SECTOR_HEADER] == int(sectorID)) & (excel[EXCEL_SPECIALIZATION_HEADER] == int(specializationID))
    ]

    # Iterate on the columns
    for name, excelHeader in EXCEL_STAGE_QUESTIONS_HEADERS.items():
        if row[excelHeader].index.size == 0:
            # No data
            setMessage(
                f"Missing data ! This specialization wasn't found in the excel Stage Questions file. (sector: {sectorID}, specialization: {specializationID})"
            )
            break
        elif row[excelHeader].index.size > 1:
            # Too much data
            setMessage(
                f"Too much data ! This specialization was found more than once in the excel Stage Questions file. (sector: {sectorID}, specialization: {specializationID})"
            )
            break
        elif row[excelHeader].get(row[excelHeader].index[0], None) == None:
            # The cell is empty. This will probably never be true because of the first two if
            setMessage(
                f"Missing data ! This cell was empty in the excel Stage Questions file. (sector: {sectorID}, specialization: {specializationID}, question: {excelHeader})"
            )
        elif row[excelHeader].get(row[excelHeader].index[0], "").strip().lower() == "oui":
            # Good data and data is "Oui"
            result.append(name)

    return result


# Data fetching
def fetchActivitySectors():
    """Fetches and parses all the available activity sectors."""
    result = []
    nameRegex = re.compile(r"^\d+ - (\D*)$")

    setMessage("Fetching all sectors...")
    page = requests.get("http://www1.education.gouv.qc.ca/sections/metiers/index.asp")
    soup = BeautifulSoup(page.content, "html.parser")

    # For each checkbox in the page
    for input in soup.find_all("input", type="checkbox"):
        sectorID = input["value"]
        name = nameRegex.match(input.find_next_sibling("label").text)

        # Handle error
        if name is None:
            setMessage(f"Missing data ! Could not find a name of Sector {sectorID}.")
            continue

        result.append((sectorID, name.group(1)))

    return result


def fetchSpecializationURLsOfSector(sectorId: str):
    """Returns all the specializations' URL of a particular sector."""
    result = []
    hrefRegex = re.compile(r"^index\.asp\?.*id=(\d+)")

    setMessage(f"Fetching all specializations of {sectorId}...")
    page = requests.get(
        f"http://www1.education.gouv.qc.ca/sections/metiers/index.asp?page=recherche&action=search&navSeq=1&sector1={sectorId}"
    )
    soup = BeautifulSoup(page.content, "html.parser")

    # Exctract the id of each specializations' link
    for specialization in soup.find_all("a", href=hrefRegex):
        s = hrefRegex.match(specialization["href"])
        if s is None:
            continue
        result.append(s.group(1))

    return result


def fetchSpecialization(specializationURL: str):
    """Returns a detailed specialization."""
    titleRegex = re.compile(r"(\d+) - ([^\t\r\n]*)")

    page = requests.get(
        f"http://www1.education.gouv.qc.ca/sections/metiers/index.asp?page=fiche&id={specializationURL}"
    )
    soup = BeautifulSoup(page.content, "html.parser")

    # Find the name of the specialization
    header = soup.find("h2")
    if header is None:
        setMessage(f"Missing data ! Specialization header not found. (sector: {specializationURL})")
        return None
    headerText = header.getText(";", True).split(";")

    result = {"n": headerText[1], "id": headerText[0], "s": []}

    # Parse each skill
    for header in soup.find_all("thead"):
        headerSections = header.find_all("th")

        # Extract id and name from the title
        titleSearch = titleRegex.search(headerSections[0].text)
        is_optional = IS_OPTIONAL_REGEX.search(str(header)) is not None
        if titleSearch is None:
            setMessage(
                f"Missing data ! The title of skill {header.find('th').text} (specialization: {specializationURL}) could not be found"
            )
            continue

        skillID = titleSearch.group(1)
        skillName = titleSearch.group(2)

        # Get the complexity
        complexity = headerSections[2].text

        # Get the two list that are inside the table under the header
        lists = header.find_next_sibling("tbody").find_all("ul")

        criteria = []
        # Criteria are situated on the first list
        for criterion in lists[0].find_all("li"):
            criteria.append(criterion.text)

        tasks = []
        # Tasks are situated on the second list
        for task in lists[1].find_all("li"):
            is_task_optional = IS_OPTIONAL_REGEX.search(str(task)) is not None
            tasks.append({"t": task.text, "o": is_task_optional})

        result["s"].append(
            {"id": skillID, "n": skillName, "x": complexity, "c": criteria, "t": tasks, "o": is_optional}
        )

    return result


# String processing
def cleanUpText(text: str):
    """Removes unwanted formating chars at the end of [text]."""
    text = text.strip()
    text = text.replace("\u009c", "oe")
    text = text.replace("\u0092", "'")
    return text


def cleanUpData(data):
    """Removes unwanted data from [data]. Cleans up all strings, remove None values from list and dict."""
    if isinstance(data, list):
        return [cleanUpData(x) for x in data if x is not None]
    elif isinstance(data, dict):
        return {key: cleanUpData(val) for key, val in data.items() if val is not None}
    elif isinstance(data, str):
        return cleanUpText(data)
    else:
        return data


# Utils
def saveJson(data: list, path: str):
    """Saves [json] as a file named [path]."""
    setMessage("Saving json...")
    with open(path, "w") as file:
        file.write(json.dumps(cleanUpData(data), indent=0, separators=(",", ":")))


def setMessage(message: str):
    """Prints the provided message and shows it to the user"""
    print(message)
    currentMessage.set(message)


def askExcelPath():
    """Asks the user for an excel file using the system's dialog"""
    file = fd.askopenfile(
        title="Choisir un classeur Excel", filetypes=(("Classeurs Excel", "*.xlsx *.xls"), ("Tous les fichiers", "*.*"))
    )

    if file is not None:
        return file.name
    else:
        return ""


# Tkinter initialisation
root = tk.Tk()
root.title("CRCRME - Générer répertoire métiers")
root.geometry("450x200")
root.resizable(False, False)
mainFrame = tk.Frame(root)
mainFrame.pack(padx=20, pady=20)


tk.Label(mainFrame, text="Entrez le chemin d'accès du classeur Excel contenant les informations SST.").pack()

frame = tk.Frame(mainFrame)
frame.pack()

excelPathSSTRisks = tk.StringVar(value="analyse_risques_metiers.xlsx")
entrySSTRisks = tk.Entry(frame, textvariable=excelPathSSTRisks)
entrySSTRisks.focus()
entrySSTRisks.pack(side="left")

fileButtonSSTRisks = tk.Button(frame, text="Parcourir", command=lambda: excelPathSSTRisks.set(askExcelPath()))
fileButtonSSTRisks.pack(side="right")


tk.Label(mainFrame, text="Entrez le chemin d'accès du classeur Excel contenant").pack()
tk.Label(mainFrame, text="les questions à poser lors du formulaire de création de stage.").pack()

frame = tk.Frame(mainFrame)
frame.pack()

excelPathStageQuestions = tk.StringVar(value="choix_questions.xlsx")
entryStageQuestions = tk.Entry(frame, textvariable=excelPathStageQuestions)
entryStageQuestions.pack(side="left")

fileButtonStageQuestions = tk.Button(
    frame, text="Parcourir", command=lambda: excelPathStageQuestions.set(askExcelPath())
)
fileButtonStageQuestions.pack(side="right")


startButton = tk.Button(mainFrame, text="Générer", command=run)
startButton.pack(side="bottom")

currentMessage = tk.StringVar()
messageLabel = tk.Label(mainFrame, textvariable=currentMessage)
messageLabel.pack(side="bottom")


if __name__ == "__main__":
    root.mainloop()
