import json
from pathlib import Path
import re
import threading
import tkinter as tk
from tkinter import filedialog as fd
from urllib.parse import unquote

# Imports to install
# > pip install pandas bs4 openpyxl playwright
import pandas as pd
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

# Constants
BASE_URL = "https://prod-da.education.gouv.qc.ca"
REPERTOIRE_URL = f"{BASE_URL}/pls/apexda/r/esp_rms/rms_gp/repertoire"
JSON_FILE_PATH = "assets/jobs-data.json"

EXCEL_SECTOR_HEADER = "N° secteur"
EXCEL_SPECIALIZATION_HEADER = "N° métiers"
EXCEL_SKILL_HEADER = "Numéro de compétences"

IS_OPTIONAL_REGEX = re.compile(r"images/ico_opt.gif")
SECTOR_REGEX = re.compile(r"^Secteur:\s*(\d+)\s*-\s*(.+)$")
SPECIALIZATION_ID_REGEX = re.compile(r"^(\d{4})\b")
SKILL_TITLE_REGEX = re.compile(r"(\d{6})\s*-\s*([^\t\r\n]*)")
SKILL_BLOCK_REGEX = re.compile(
    r"(?ms)^(?P<id>\d{6})\s*-\s*(?P<name>.+?)\s+Ajouter à mon plan\s+Complexité\s*:\s*(?P<complexity>\d+)\s+"
    r"Critères de performance\s+(?P<criteria>.*?)\s+Tâches\s+(?P<tasks>.*?)(?=^\d{6}\s*-\s*|\Z)"
)

# Data to change
EXCEL_SST_RISKS_HEADERS = {
    # json : excel
    "c": "1. Risques Chimiques",
    "b": "2. Risques Biologiques",
    "e": "3. Risques liés aux machines et aux équipements",
    "f": "4. Risques de chutes de hauteur et de plain-pied",
    "of": "5. Risques liés aux chutes d'objets",
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
        try:
            for element in ui:
                element["state"] = "disabled"
            start(excelPathSSTRisks.get(), excelPathStageQuestions.get())
        finally:
            for element in ui:
                element["state"] = "normal"

    threading.Thread(target=target).start()


def start(excelPathSSTRisks: str, excelPathStageQuestions: str):
    """Starts the main script"""
    try:
        excelSSTRisks = pd.read_excel(excelPathSSTRisks)
    except FileNotFoundError:
        setMessage("Could not read the SST excel file.")
        return

    try:
        excelStageQuestions = pd.read_excel(excelPathStageQuestions)
    except FileNotFoundError:
        setMessage("Could not read the Stage excel file.")
        return

    try:
        data = fetchJobsData()
    except Exception as error:
        setMessage(f"Could not fetch jobs data: {error}")
        return

    for sector in data:
        sectorID = sector["id"]
        for specialization in sector["s"]:
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

    saveJson(data, JSON_FILE_PATH)
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
def fetchJobsData():
    """Fetches the current repertoire and returns it in the app's compact schema."""
    setMessage("Fetching all jobs from the repertoire...")

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        context = browser.new_context()
        repertoirePage = context.new_page()
        repertoirePage.goto(REPERTOIRE_URL, wait_until="networkidle")

        sectors = []
        sectorIndex = {}
        specializationCount = 0

        while True:
            entries = parseRepertoirePage(repertoirePage.content())

            for entry in entries:
                sector = sectorIndex.get(entry["sectorId"])
                if sector is None:
                    sector = {"n": entry["sectorName"], "id": entry["sectorId"], "s": []}
                    sectorIndex[entry["sectorId"]] = sector
                    sectors.append(sector)

                specialization = fetchSpecialization(
                    context,
                    entry["detailUrl"],
                    fallbackSpecializationId=entry["specializationId"],
                    fallbackSpecializationName=entry["specializationName"],
                )
                if specialization is None:
                    continue

                sector["s"].append(specialization)
                specializationCount += 1
                setMessage(f"Fetched {specializationCount} specializations...")

            if not goToNextRepertoirePage(repertoirePage):
                break

        browser.close()

    return sectors


def parseRepertoirePage(html: str):
    """Parses one repertoire result page and returns specialization links grouped by sector context."""
    result = []
    soup = BeautifulSoup(html, "html.parser")
    currentSectorId = None
    currentSectorName = None

    for row in soup.find_all("tr"):
        rowText = cleanUpText(row.get_text(" ", strip=True))
        if not rowText:
            continue

        sectorMatch = SECTOR_REGEX.match(rowText)
        if sectorMatch is not None:
            currentSectorId = sectorMatch.group(1)
            currentSectorName = sectorMatch.group(2)
            continue

        cells = row.find_all("td")
        if len(cells) < 4 or currentSectorId is None or currentSectorName is None:
            continue

        detailLink = cells[0].find("a", href=True)
        if detailLink is None or "action$a-dialog-open" not in detailLink["href"]:
            continue

        specializationId = cleanUpText(cells[1].get_text())
        specializationName = cleanUpText(cells[3].get_text())
        if not specializationId or not specializationName:
            continue

        result.append(
            {
                "sectorId": currentSectorId,
                "sectorName": currentSectorName,
                "specializationId": specializationId,
                "specializationName": specializationName,
                "detailUrl": extractDetailUrl(detailLink["href"]),
            }
        )

    return result


def extractDetailUrl(dialogHref: str):
    """Extracts the inner APEX dialog URL from the result table link."""
    encodedUrl = dialogHref.split("url=", 1)[1].split("&appId=", 1)[0]
    return unquote(encodedUrl)


def goToNextRepertoirePage(page):
    """Moves to the next repertoire page if pagination is available."""
    nextButtons = page.locator('button[title="Suivant"], button[aria-label="Suivant"]')
    if nextButtons.count() == 0:
        return False

    nextButton = nextButtons.first
    if nextButton.is_disabled():
        return False

    firstCell = page.locator("#METIER_data_panel tr td:nth-child(2)").first
    previousValue = firstCell.inner_text() if firstCell.count() > 0 else ""
    nextButton.click(force=True)

    if previousValue:
        try:
            page.wait_for_function(
                """
                previousValue => {
                    const firstCell = document.querySelector('#METIER_data_panel tr td:nth-child(2)');
                    return firstCell && firstCell.textContent.trim() !== previousValue;
                }
                """,
                previousValue,
                timeout=5000,
            )
        except Exception:
            page.wait_for_timeout(1000)

    return True


def fetchSpecialization(context, detailUrl: str, fallbackSpecializationId=None, fallbackSpecializationName=None):
    """Fetches a specialization detail page and parses its skills."""
    detailPage = context.new_page()

    try:
        detailPage.goto(f"{BASE_URL}{detailUrl}", wait_until="networkidle")
        bodyText = cleanUpText(detailPage.locator("body").inner_text())
        if "Métier" not in bodyText:
            setMessage(f"Missing data ! Specialization page did not load correctly. ({detailUrl})")
            return None

        html = detailPage.content()
        specializationId, specializationName = parseSpecializationIdentity(bodyText)
        specializationId = specializationId or fallbackSpecializationId
        specializationName = specializationName or fallbackSpecializationName
        if specializationId is None or specializationName is None:
            setMessage(f"Missing data ! Specialization header not found. ({detailUrl})")
            return None

        skills = parseSkillsFromHtml(html)
        if not skills:
            skills = parseSkillsFromText(bodyText)

        if not skills:
            setMessage(f"Missing data ! No skills found for specialization {specializationId}.")
            return None

        return {"n": specializationName, "id": specializationId, "s": skills}
    finally:
        detailPage.close()


def parseSpecializationIdentity(bodyText: str):
    """Extracts the specialization id and title from the detail page text."""
    lines = [cleanUpText(line) for line in bodyText.splitlines() if cleanUpText(line)]
    specializationId = None
    specializationName = None

    for index, line in enumerate(lines):
        if SPECIALIZATION_ID_REGEX.match(line):
            specializationId = SPECIALIZATION_ID_REGEX.match(line).group(1)
            if index + 1 < len(lines):
                specializationName = lines[index + 1]
            break

    return specializationId, specializationName


def parseSkillsFromHtml(html: str):
    """Parses the skill tables when the detail page exposes structured table markup."""
    result = []
    soup = BeautifulSoup(html, "html.parser")

    for header in soup.find_all("thead"):
        headerSections = header.find_all("th")
        if len(headerSections) < 3:
            continue

        titleSearch = SKILL_TITLE_REGEX.search(cleanUpText(headerSections[0].get_text(" ", strip=True)))
        if titleSearch is None:
            continue

        body = header.find_next_sibling("tbody")
        if body is None:
            continue

        lists = body.find_all("ul")
        if len(lists) < 2:
            continue

        criteria = [cleanUpText(item.get_text(" ", strip=True)) for item in lists[0].find_all("li")]
        tasks = []
        for task in lists[1].find_all("li"):
            tasks.append(
                {
                    "t": cleanUpText(task.get_text(" ", strip=True)),
                    "o": IS_OPTIONAL_REGEX.search(str(task)) is not None,
                }
            )

        result.append(
            {
                "id": titleSearch.group(1),
                "n": cleanUpText(titleSearch.group(2)),
                "x": cleanUpText(headerSections[2].get_text(" ", strip=True)),
                "c": criteria,
                "t": tasks,
                "o": IS_OPTIONAL_REGEX.search(str(header)) is not None,
            }
        )

    return result


def parseSkillsFromText(bodyText: str):
    """Fallback parser for the rendered text content of the detail page."""
    result = []

    for match in SKILL_BLOCK_REGEX.finditer(bodyText):
        criteria = [cleanUpText(line) for line in match.group("criteria").splitlines() if cleanUpText(line)]
        tasks = [
            {"t": cleanUpText(line), "o": False} for line in match.group("tasks").splitlines() if cleanUpText(line)
        ]

        result.append(
            {
                "id": match.group("id"),
                "n": cleanUpText(match.group("name")),
                "x": match.group("complexity"),
                "c": criteria,
                "t": tasks,
                "o": False,
            }
        )

    return result


# String processing
def cleanUpText(text: str):
    """Removes unwanted formating chars at the end of [text]."""
    text = text.strip()
    text = text.replace("\xa0", " ")
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
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as file:
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
