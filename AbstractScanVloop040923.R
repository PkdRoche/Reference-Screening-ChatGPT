library(httr)
library(jsonlite)

# Define your OpenAI API key here
api_key <- "sk-xxx"

# Global counter variable
counter <- 0

# Read the system request from the external .txt file
system_request <- readLines("request_template50v12r8.txt")
# Concatenate the system_request into a single string
full_system_request <- paste(system_request, collapse = "\n")

analyze_text_with_chatgpt <- function(Title, Abstract) {

  decisions <- vector("character", 7)
  
  for (i in 1:7) {
    valid_response_received <- FALSE
    retries <- 0
    max_retries <- 3  # Set maximum number of retries
    while (!valid_response_received && retries < max_retries) {
      
     # Set up the messages for ChatGPT analysis
    messages <- list(
      list(role = "system", content = full_system_request), 
      list(role = "user", content = paste0("classify the paper based on the title: '", Title, "' and abstract: '", Abstract, "'"))
    )
    
    response <- tryCatch({
      POST(
        url = "https://api.openai.com/v1/chat/completions",
        add_headers(
          "Authorization" = paste0("Bearer ", api_key),
          "Content-Type" = "application/json"
        ),
        body = list(
          model = "gpt-3.5-turbo",
          messages = messages,
          temperature = 0.5,
          max_tokens = 1000  # Limit the response to 800 tokens
        ),
        encode = "json",
        timeout(50)  # Set a timeout of 30 seconds for the API call
      )
    }, error = function(e) {
      if (grepl("Timeout was reached", e$message)) {
        print(paste("Timeout error on refline:", counter))
        retries <- retries + 1
        Sys.sleep(2^retries)  # Exponential backoff
      } else {
        print(paste("refline :", counter))
        print("Error with title:")
        print("Error with abstract:")
        print(e$message)
        decisions[i] <- "error"
        Sys.sleep(3)
      }
      NULL
    })
    Sys.sleep(2)
    print (content(response)$choices[[1]]$message$content)
    # Check if the response has the expected structure
    if (!is.null(response) && "choices" %in% names(content(response))) {
      response_text <- content(response)$choices[[1]]$message$content
     
      # Check for empty or null response_text
      if (is.null(response_text) || response_text == "") {
        print(paste("No response text for title:", Title, "Retrying..."))
        retries <- retries + 1
        Sys.sleep(2)  # Optional: Sleep for 2 seconds before retrying
      } else {
        # Valid response received, exit while loop
        valid_response_received <- TRUE
        
        # Use regex to identify the decision (selected, rejected, uncertain) anywhere in the response
        classification <- regmatches(response_text, gregexpr("(Selected|selected|Rejected|rejected|Uncertain|uncertain)", response_text))
        
        # Check if decision is extracted
        if (length(classification[[1]]) > 0) {
          decisions[i] <- tolower(classification[[1]][1])
        } else {
          decisions[i] <- "unexpected_response"
          print(paste("Unexpected response for title:", Title))
          print(response_text)
        }
      }
    } else {
      print("Unexpected API response structure. Retrying...")
      retries <- retries + 1
      Sys.sleep(2)  # Optional: Sleep for 2 seconds before retrying
    }
    }  # End of while loop
    # If after max retries, still no valid response, return error decision
    if (!valid_response_received) {
      return(list(Decision = "error", Comment = "Max retries reached without a valid response"))
    }   

  # Filter out NA values but retain "error" and "unexpected_response" for transparency
  decisions <- decisions[!is.na(decisions)]
  
  # Filter out "error" and "unexpected_response" for the decision-making process
  valid_decisions <- decisions[!decisions %in% c("error", "unexpected_response")]
  
  # Determine the final decision based on the new criteria
  total_responses <- length(valid_decisions)
  selected_percentage <- sum(valid_decisions == "selected") / total_responses
  rejected_percentage <- sum(valid_decisions == "rejected") / total_responses
  
  if (selected_percentage >= 0.7) {
    final_decision <- "selected"
  } else if (rejected_percentage >= 0.7) {
    final_decision <- "rejected"
  } else {
    final_decision <- "uncertain"
  }
  } # End of for loop
 
   # Counter and printing decisions
  .GlobalEnv$counter <- .GlobalEnv$counter + 1
  percentage_completion <- (.GlobalEnv$counter / nrow(data)) * 100
  print(paste(round(percentage_completion, 2), "% completed"))
  print(paste("final decision is ", final_decision))

  # Return the most frequent decision and its associated comment
  return(list(Decision = final_decision, Comment = paste("Decision based on", length(decisions), "runs:", paste(decisions, collapse=", "))))
}

# Read the .txt file (assuming tab-separated values)
data <- read.delim("input50Sample2.txt", header = TRUE, stringsAsFactors = FALSE)
data <- data[!is.na(data$Abstract) & data$Abstract != "", ]

# Apply the ChatGPT 3.5 turbo analysis function and store the results in a new data frame
results <- mapply(analyze_text_with_chatgpt, data$Title, data$Abstract, SIMPLIFY = FALSE)

# Add the decisions and comments to the original data frame
data$Decision <- sapply(results, `[[`, "Decision")
data$Comments <- sapply(results, `[[`, "Comment")

# Write results to a new CSV file
write.table(data[, c("Code", "Title", "Decision", "Comments")], "output50Samp2v12r8temp05.txt", sep = "\t", row.names = FALSE, quote = FALSE)
