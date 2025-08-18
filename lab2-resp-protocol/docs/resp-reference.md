# RESP Protocol Reference

## Data Types

### 1. Simple Strings (+)
- Format: `+<string>\r\n`
- Example: `+OK\r\n`
- Use: Status responses

### 2. Errors (-)
- Format: `-<error>\r\n`
- Example: `-ERR unknown command\r\n`
- Use: Error messages

### 3. Integers (:)
- Format: `:<number>\r\n`
- Example: `:42\r\n`
- Use: Numeric responses

### 4. Bulk Strings ($)
- Format: `$<length>\r\n<data>\r\n`
- Example: `$5\r\nhello\r\n`
- NULL: `$-1\r\n`
- Use: String values

### 5. Arrays (*)
- Format: `*<count>\r\n<elements>`
- Example: `*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n`
- NULL: `*-1\r\n`
- Use: Multiple values

## Common Commands in RESP

### SET Command
```
Client: *3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n
Server: +OK\r\n
```

### GET Command
```
Client: *2\r\n$3\r\nGET\r\n$3\r\nkey\r\n
Server: $5\r\nvalue\r\n
```

### MGET Command
```
Client: *3\r\n$4\r\nMGET\r\n$4\r\nkey1\r\n$4\r\nkey2\r\n
Server: *2\r\n$6\r\nvalue1\r\n$6\r\nvalue2\r\n
```

### Error Response
```
Client: *1\r\n$7\r\nINVALID\r\n
Server: -ERR unknown command 'INVALID'\r\n
```

## Protocol Analysis Tips

1. **Use MONITOR carefully** - It impacts performance in production
2. **Pipeline commands** - Reduce round-trip time
3. **Batch operations** - Use MSET/MGET instead of multiple SET/GET
4. **Watch for errors** - Lines starting with `-`
5. **Measure latency** - Use `--latency` and `--latency-history`

## Performance Patterns

### Inefficient Pattern
```bash
for key in keys:
    redis.get(key)  # Multiple round trips
```

### Efficient Pattern
```bash
redis.mget(keys)  # Single round trip
```

### Transaction Pattern
```
MULTI
command1
command2
command3
EXEC
```

All commands sent together, executed atomically.
