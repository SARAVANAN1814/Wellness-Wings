const { Pool } = require('pg');
const fs = require('fs');
const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'wellness_wings',
    password: '123456789',
    port: 5432,
});

async function dump() {
    let out = '';
    const { rows: tables } = await pool.query(`SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'`);
    for (const t of tables) {
        out += `\nTable: ${t.table_name}\n`;
        const { rows: cols } = await pool.query(`SELECT column_name, data_type, character_maximum_length, column_default, is_nullable FROM information_schema.columns WHERE table_name = $1`, [t.table_name]);
        cols.forEach(c => {
            out += `  ${c.column_name} | ${c.data_type} ${c.character_maximum_length ? '('+c.character_maximum_length+')' : ''} | Default: ${c.column_default} | Nullable: ${c.is_nullable}\n`;
        });
    }
    fs.writeFileSync('schema_utf8.txt', out, 'utf8');
    console.log('Done');
    process.exit(0);
}
dump();
