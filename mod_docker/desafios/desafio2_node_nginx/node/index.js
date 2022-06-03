const randomName = require('node-random-name')
const express = require('express')
const app = express()
const port = 3000
const config = {
    host: 'db',
    user: 'root',
    password: 'root',
    database: 'nodedb'
};
const mysql = require('mysql')

function executeQuery(sql) {
    const connection = mysql.createConnection(config)
    connection.query(sql)
    connection.end()
}

app.get('/', (req, res) => {
    executeQuery(`insert into people(name) values('${randomName()}')`)
    var connection = mysql.createConnection(config)
    connection.query("select name from people", function(err, result, fields){
        if (err) throw err;
        res.send('<h1>Full Cycle</h1><br>' + JSON.stringify(result));
    });
})

app.listen(port, ()=>{
    console.log('Rodando na porta ' + port)
})