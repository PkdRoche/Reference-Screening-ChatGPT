Project Name: ChatGPT Text Analysis Automation

This project is designed to automate the process of sending texts (specifically titles and abstracts of papers) to OpenAI's ChatGPT for classification or analysis. It uses R programming language and leverages several libraries to handle HTTP requests, JSON data, and text processing.

Dependencies:

    R programming environment
    httr library for handling HTTP requests
    jsonlite library for parsing JSON data

Setup:

    Ensure you have R installed on your system. You can download it from CRAN.
    Install the required R packages by running the following commands in your R console:

    install.packages("httr")
    install.packages("jsonlite")

    Obtain an API key from OpenAI by creating an account at OpenAI and accessing the API section.

Files Description:

    script.R: The main script containing the code to process and send requests to ChatGPT.
    request_template.txt: A template for the system message to be sent along with each ChatGPT request. Modify this file to change the initial context for ChatGPT.
    input.txt: A tab-separated values (TSV) file containing the codes, titles, and abstracts of papers to be analyzed. Ensure it has headers named Code, Title, and Abstract.
    output_text.txt: The output file where the decisions and comments from ChatGPT analysis will be saved in a tab-separated format.

Usage Instructions:

    Update the api_key variable in the script.R file with your OpenAI API key.
    Place your input.txt file in the same directory as the script. This file should contain the data to be analyzed.
    Run the script in your R environment. The script will read the input.txt file, process each title and abstract through ChatGPT, and save the results in output_text.txt.

Functionality:

    The script reads titles and abstracts from input.txt, sends them to ChatGPT for analysis, and collects the responses.
    It attempts each request up to three times in case of failure (e.g., timeouts).
    Decisions are based on the response from ChatGPT and are categorized as selected, rejected, or uncertain.
    The final decision for each text is determined by the majority decision from seven attempts, with thresholds for deciding if a text is selected or rejected.

Notes:

    Modify the request template in request_template.txt as needed to fit your analysis context.
    Adjust the max_retries and temperature parameters in the script to optimize request success rates and response variability.
    The script implements a basic error handling and retry mechanism to manage common issues like timeouts and unexpected API responses.

Disclaimer:
This project is not affiliated with OpenAI. Please use the OpenAI API responsibly and in accordance with OpenAI's use case policies and guidelines.
