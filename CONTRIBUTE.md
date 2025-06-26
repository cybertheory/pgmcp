# 🤝 Contributing to MCP PostgREST Extension

Thank you for your interest in contributing to `mcp_postgrest`! This guide will help you get started with contributing to this PostgreSQL extension that brings AI-powered tool interfaces to your database.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style & Conventions](#code-style--conventions)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)
- [Documentation](#documentation)
- [Release Process](#release-process)

---

## 🚀 Getting Started

### Prerequisites

- PostgreSQL 12+ (recommended: 15+)
- PostgREST
- Docker (optional, for containerized development)
- Basic knowledge of PostgreSQL, PL/pgSQL, and JSON Schema

### Areas for Contribution

- 🐛 **Bug fixes** - Help us squash bugs
- ✨ **New features** - AI tool enhancements, MCP protocol improvements
- 📚 **Documentation** - Improve guides, examples, and API docs
- 🧪 **Testing** - Add test cases and improve test coverage
- 🔧 **DevOps** - Docker improvements, CI/CD enhancements
- 🎨 **Examples** - Real-world usage examples and tutorials

---

## 🛠️ Development Setup

### Option 1: Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/cybertheory/pgmcp.git
   cd pgmcp
   ```

2. **Install PostgreSQL extension**
   ```bash
   sudo cp mcp_postgrest.control /usr/share/postgresql/$(pg_config --version | cut -d' ' -f2 | cut -d'.' -f1,2)/extension/
   sudo cp sql/mcp_postgrest--0.1.2.sql /usr/share/postgresql/$(pg_config --version | cut -d' ' -f2 | cut -d'.' -f1,2)/extension/
   ```

3. **Create test database**
   ```bash
   createdb mcp_test
   psql mcp_test -c "CREATE EXTENSION mcp_postgrest;"
   ```

### Option 2: Docker Development

1. **Build and run container**
   ```bash
   docker build -t mcp_postgrest_dev .
   docker run -p 5432:5432 -p 3000:3000 -e POSTGRES_PASSWORD=password mcp_postgrest_dev
   ```

2. **Connect to test database**
   ```bash
   psql -h localhost -U postgres -d postgres
   ```

### Development Workflow

1. Create a feature branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Test thoroughly (see [Testing](#testing))
4. Commit with clear messages
5. Push and create a Pull Request

---

## 📝 Code Style & Conventions

### SQL/PL/pgSQL Style

- **Indentation**: 2 spaces (no tabs)
- **Keywords**: UPPERCASE for SQL keywords (`SELECT`, `FROM`, `WHERE`)
- **Identifiers**: lowercase_with_underscores
- **Functions**: Descriptive names with consistent prefixes (`mcp_`, `tool_`)

**Example:**
```sql
CREATE OR REPLACE FUNCTION mcp_create_example_tool(params JSONB)
RETURNS JSONB AS $
DECLARE
  result JSONB;
BEGIN
  -- Clear, descriptive variable names
  SELECT to_jsonb(row) INTO result
  FROM (
    SELECT 
      params->>'name' AS tool_name,
      current_timestamp AS created_at
  ) row;
  
  RETURN result;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Naming Conventions

- **Tables**: `snake_case` (e.g., `mcp_tools`)
- **Functions**: `action_subject_context` (e.g., `create_crud_tools_for_table`)
- **Variables**: `snake_case` and descriptive
- **Constants**: `UPPER_SNAKE_CASE`

### Documentation

- Add inline comments for complex logic
- Document function parameters and return values
- Include usage examples in function comments

---

## 🧪 Testing

### Manual Testing

1. **Basic Extension Loading**
   ```sql
   CREATE EXTENSION IF NOT EXISTS mcp_postgrest;
   SELECT * FROM mcp_tools;
   ```

2. **CRUD Auto-generation**
   ```sql
   CREATE TABLE test_products(name TEXT, price INT);
   SELECT * FROM mcp_tools WHERE name LIKE '%test_products%';
   SELECT call_tool('create_test_products', '{"name": "Test Item", "price": 100}');
   ```

3. **AI Tool Generation**
   ```sql
   SELECT generate_ai_tool(
     'openai',
     'test-key',
     'test_tool',
     'Test description',
     ARRAY['test_products']
   );
   ```

### PostgREST Integration Testing

```bash
# Start PostgREST
postgrest postgrest.conf.template &

# Test REST endpoint
curl -X POST http://localhost:3000/rpc/call_tool \
  -H "Content-Type: application/json" \
  -d '{"tool_name": "create_test_products", "args": {"name": "REST Test", "price": 50}}'
```

### Test Checklist

Before submitting PRs, ensure:
- [ ] Extension loads without errors
- [ ] Basic tool creation/calling works
- [ ] CRUD auto-generation functions
- [ ] PostgREST integration works
- [ ] No regression in existing functionality
- [ ] SQL injection protection works
- [ ] Role-based access control functions

---

## 📤 Submitting Changes

### Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch from `main`
3. **Make** your changes with clear, logical commits
4. **Test** thoroughly (see Testing section)
5. **Update** documentation if needed
6. **Submit** a Pull Request

### PR Requirements

- **Clear title** describing the change
- **Detailed description** explaining:
  - What problem does this solve?
  - How does it work?
  - Any breaking changes?
- **Test results** showing your changes work
- **Updated documentation** if applicable

### Commit Message Format

```
type(scope): brief description

Longer explanation if needed, including:
- Why this change was made
- Any side effects or considerations
- References to issues (#123)

Examples:
feat(ai): add support for Claude-3.5 Sonnet model
fix(crud): handle edge case in auto-table generation
docs(readme): update installation instructions
```

---

## 🐛 Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. **PostgreSQL version** (`SELECT version();`)
2. **Extension version** (check `mcp_postgrest.control`)
3. **Steps to reproduce**
4. **Expected vs actual behavior**
5. **Error messages** (full stack traces)
6. **Environment details** (OS, Docker, etc.)

### Feature Requests

For new features, describe:
- **Use case**: What problem would this solve?
- **Proposed solution**: How should it work?
- **Alternatives**: What other approaches did you consider?
- **Impact**: Who would benefit from this feature?

---

## 📚 Documentation

### What to Document

- **New functions**: Purpose, parameters, return values, examples
- **Configuration options**: How to set and what they do  
- **Integration guides**: Step-by-step setup instructions
- **Examples**: Real-world usage scenarios

### Documentation Style

- Use clear, concise language
- Include working code examples
- Add expected output where helpful
- Use consistent formatting and structure

---

## 🚢 Release Process

### Version Numbering

We follow semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible

### Release Steps

1. Update version in `mcp_postgrest.control`
2. Create new SQL migration file: `mcp_postgrest--X.Y.Z.sql`
3. Update `README.md` with new features/changes
4. Tag release: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
5. Create GitHub release with changelog

---

## 🤖 AI Integration Guidelines

When contributing AI-related features:

- **Provider agnostic**: Support multiple AI providers when possible
- **Error handling**: Graceful degradation when AI services are unavailable
- **Security**: Never log API keys; validate all inputs
- **Rate limiting**: Consider API limits and costs
- **Documentation**: Include example prompts and expected outputs

---

## 🎯 Getting Help

- **Issues**: Create GitHub issues for questions
- **Discussions**: Use GitHub Discussions for ideas
- **Code Review**: Tag maintainers for review help

---

## 📜 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers learn and contribute
- Maintain a professional, collaborative environment

---

**Thank you for contributing to MCP PostgREST! 🚀**

Every contribution, no matter how small, helps make this project better for everyone.