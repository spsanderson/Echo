# Building a Local LLM RAG Application for SQL Queries using SPARC Framework

Great project! Let's structure this using the SPARC framework to build a robust text-to-SQL application with Ollama.

---

## 1️⃣ **Specification**

### **Project Goals**

- Enable natural language queries against SQL databases
- Use Ollama for local LLM inference (privacy & cost-effective)
- Return both SQL query and execution results
- Support conversational context for follow-up questions

### **Core Requirements**

- **Local LLM**: Ollama with models like CodeLlama, Llama2, or Mistral
- **RAG Framework**: Store and retrieve SQL schema information, example queries, and documentation
- **Database**: SQL Server (based on your example)
- **Python Stack**: LangChain, Ollama Python client, SQL connectors
- **Output Format**: SQL query + formatted results

### **Constraints**

- Must run entirely locally (no API keys/cloud services)
- Handle complex joins and date functions
- Maintain query history for context
- Safe SQL execution (read-only recommended)

### **Success Criteria**

- Accurate SQL generation for common business queries
- Sub-5 second response time
- 85%+ query accuracy on domain-specific questions

### Support Documents

- ![Functional Requirements](Functional Requirements.md)

---

## 2️⃣ **Pseudocode**

```
INITIALIZE APPLICATION:
    Load database schema into vector store
    Load example query pairs (NL → SQL)
    Initialize Ollama LLM
    Connect to SQL database
  
MAIN QUERY LOOP:
    User inputs natural language question
  
    RETRIEVE CONTEXT:
        Search vector store for:
            - Relevant table schemas
            - Similar past queries
            - Column descriptions
  
    GENERATE SQL:
        Construct prompt with:
            - User question
            - Retrieved schema context
            - Few-shot examples
            - Database dialect hints
      
        Send to Ollama LLM
        Parse SQL from response
      
    VALIDATE SQL:
        Check for dangerous operations (DROP, DELETE, UPDATE)
        Verify table/column names exist
      
    EXECUTE QUERY:
        Run SQL against database
        Catch and handle errors
      
    FORMAT RESPONSE:
        Display SQL query (formatted)
        Display result data (table/JSON)
        Store in conversation history
      
    UPDATE CONTEXT:
        Add successful query to vector store
        Maintain conversation memory
```

---

## 3️⃣ **Architecture**

### **System Components**

#### **A. Vector Store Layer**

- **Purpose**: Store schema metadata, example queries for RAG retrieval
- **Technology**: Chroma or FAISS (local, no external dependencies)
- **Embeddings**: Ollama's built-in embedding models or sentence-transformers
- **Stored Data**:
  - Table schemas with descriptions
  - Column metadata (types, constraints)
  - Historical query pairs
  - Domain-specific terminology

#### **B. LLM Layer**

- **Model**: Ollama running CodeLlama-7B or SQLCoder
- **Configuration**:
  ```python
  temperature: 0.1  # Low for deterministic SQL
  max_tokens: 512
  stop_sequences: [";", "```"]
  ```

#### **C. Database Interface Layer**

- **Connector**: pyodbc or pymssql for SQL Server
- **Connection Pool**: Maintain persistent connections
- **Security**: Read-only user, query timeouts

#### **D. Query Processing Pipeline**

```
User Input → Intent Classification → Context Retrieval → 
SQL Generation → Validation → Execution → Response Formatting
```

### **Data Flow Diagram**

```
┌─────────────┐
│   User UI   │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│  Query Processor    │
│  - Parse intent     │
│  - Maintain context │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│   RAG Retriever     │
│  - Schema lookup    │
│  - Example queries  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│   Ollama LLM        │
│  - SQL generation   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  SQL Validator      │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  SQL Database       │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Response Formatter │
└─────────────────────┘
```

---

## 4️⃣ **Refinement**

### **Key Implementation Details**

#### **A. Schema Ingestion**

```python
# Extract and embed database schema
def ingest_schema(connection_string):
    - Query INFORMATION_SCHEMA tables
    - Extract table/column metadata
    - Create embeddings for each table description
    - Store in vector database
    - Include sample data for context
```

#### **B. Prompt Engineering**

The prompt structure is critical for accurate SQL generation:

```python
prompt_template = """
You are a SQL expert. Generate ONLY the SQL query, no explanations.

Database Schema:
{schema_context}

Example Queries:
{few_shot_examples}

User Question: {user_question}

SQL Query:"""
```

#### **C. Conversation Memory**

- Use LangChain's `ConversationBufferMemory`
- Track last 5-10 queries for context
- Enable follow-up questions like "Show me the top 10"

#### **D. Error Handling**

```python
- SQL syntax errors → Retry with error message in prompt
- Timeout errors → Suggest query optimization
- Permission errors → Log and notify user
- Empty results → Provide helpful suggestions
```

#### **E. SQL Safety Validator**

```python
def validate_sql(query):
    prohibited_keywords = ['DROP', 'DELETE', 'UPDATE', 'INSERT', 'TRUNCATE']
    query_upper = query.upper()
  
    for keyword in prohibited_keywords:
        if keyword in query_upper:
            raise SecurityError(f"Prohibited operation: {keyword}")
  
    return True
```

---

## 5️⃣ **Completion**

### **Technology Stack**

```python
# Core dependencies
ollama                 # LLM inference
langchain             # RAG framework
chromadb              # Vector store
pyodbc                # SQL Server connector
sentence-transformers # Embeddings
streamlit             # UI (optional)
```

### **Project Structure**

```
sql-rag-app/
├── config/
│   ├── database.yaml      # DB connection configs
│   └── ollama.yaml        # Model settings
├── src/
│   ├── schema_loader.py   # Extract DB schema
│   ├── vector_store.py    # RAG retrieval
│   ├── llm_client.py      # Ollama interface
│   ├── query_engine.py    # Main orchestration
│   ├── validators.py      # SQL safety checks
│   └── formatters.py      # Output formatting
├── data/
│   ├── example_queries.json  # Few-shot examples
│   └── vector_db/         # Chroma storage
├── tests/
│   └── test_queries.py
├── app.py                 # Main application
└── requirements.txt
```

### **Minimal Working Example**

```python
from langchain.llms import Ollama
from langchain.prompts import PromptTemplate
import pyodbc

# Initialize Ollama
llm = Ollama(model="codellama", temperature=0.1)

# Create prompt
template = """Given this schema: {schema}
Convert to SQL: {question}
SQL:"""
prompt = PromptTemplate(template=template, input_variables=["schema", "question"])

# Generate SQL
chain = prompt | llm
sql_query = chain.invoke({
    "schema": "Table: pt_accounting_reporting_alt (acct_type, dsch_date)",
    "question": "How many inpatient accounts discharged yesterday?"
})

# Execute
conn = pyodbc.connect('connection_string')
result = conn.execute(sql_query).fetchall()

print(f"SQL: {sql_query}")
print(f"Result: {result}")
```

### **Testing Strategy**

1. **Unit Tests**: Test individual components (schema loader, validator)
2. **Integration Tests**: End-to-end query execution
3. **Benchmark Suite**: Common business queries with expected results
4. **User Acceptance**: Domain experts validate SQL accuracy

### **Deployment Checklist**

- ✅ Install Ollama and pull appropriate model
- ✅ Set up read-only database user
- ✅ Ingest initial schema and examples
- ✅ Configure query timeouts and rate limits
- ✅ Document supported query patterns
- ✅ Create user guide with examples

### **Next Steps**

1. Start with schema ingestion and vector store setup
2. Build basic LLM → SQL pipeline
3. Add RAG retrieval for context
4. Implement safety validators
5. Create simple UI (CLI or Streamlit)
6. Iterate on prompt engineering with real queries

This RAG-based approach [[7]] will allow your application to leverage enterprise data sources effectively [[1]], making it database-agnostic and extensible [[2]]. The use of Ollama keeps everything local while maintaining strong SQL generation capabilities.
