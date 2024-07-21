#include <lean/lean.h>
#include "postgresql/libpq-fe.h"
#include "stdlib.h"

LEAN_EXPORT lean_obj_res get_postgres_employee_cont(lean_object* o) {
    PGconn *conn = PQconnectdb("dbname=db_test user=postgres password=password host=postgre_db");
    
    if (PQstatus(conn) != CONNECTION_OK) {
        printf("%s", PQerrorMessage(conn));
        exit(1);
    }

    PGresult *res = PQexec(conn, "SELECT name, salary FROM employee ORDER BY name");
    if (PQresultStatus(res) != PGRES_TUPLES_OK){
        printf("%s", PQerrorMessage(conn));
        exit(1);
    }

    lean_object* tuple = lean_alloc_ctor(0, 2, 0);
    lean_ctor_set(tuple, 0, lean_box_uint64(atoi(PQgetvalue(res, 0, 1))));
    lean_ctor_set(tuple, 1, lean_mk_string(PQgetvalue(res, 0, 0)));

    PQclear(res);
    PQfinish(conn);

    return lean_io_result_mk_ok(tuple);
}