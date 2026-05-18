const fs = require('fs');
const path = require('path');

// Configuration
const BACKUP_FILE = 'h:\\allan\\Proyectos\\Flutter\\workia\\backupFileFull.json';
const EMPRESA_ID = 'EMP_SERVICIOS_DEMO';
const NUM_RECORDS = 15;

function getTimestamp() {
    const now = Date.now();
    const seconds = Math.floor(now / 1000);
    const nanoseconds = (now % 1000) * 1000000;
    return {
        "__type__": "timestamp",
        "_seconds": seconds,
        "_nanoseconds": nanoseconds
    };
}

function generateId(prefix, name = null) {
    const timestamp = Date.now();
    if (name) {
        const cleanName = name.toUpperCase().replace(/ /g, '_');
        return `${prefix}_${cleanName}_${timestamp}`;
    }
    return `${prefix}_${timestamp}_${Math.floor(Math.random() * 9000) + 1000}`;
}

function loadData() {
    const rawData = fs.readFileSync(BACKUP_FILE, 'utf-8');
    return JSON.parse(rawData);
}

function saveData(data) {
    fs.writeFileSync(BACKUP_FILE, JSON.stringify(data, null, 2), 'utf-8');
}

function generateUsers(data) {
    console.log("Generating users...");
    const roles = ['PERF_TEC', 'PERF_ADMIN', 'PERF_FIN'];
    const firstNames = ['Juan', 'Maria', 'Pedro', 'Ana', 'Luis', 'Sofia', 'Carlos', 'Lucia', 'Miguel', 'Elena', 'Roberto', 'Patricia', 'David', 'Carmen', 'Jose'];
    const lastNames = ['Perez', 'Gomez', 'Rodriguez', 'Lopez', 'Martinez', 'Sanchez', 'Garcia', 'Fernandez', 'Gonzalez', 'Diaz', 'Vasquez', 'Castro', 'Ruiz', 'Jimenez', 'Torres'];

    const newUsers = [];
    for (let i = 0; i < NUM_RECORDS; i++) {
        const first = firstNames[Math.floor(Math.random() * firstNames.length)];
        const last = lastNames[Math.floor(Math.random() * lastNames.length)];
        const name = `${first} ${last}`;
        const role = roles[Math.floor(Math.random() * roles.length)];
        const userId = `USR_${first.toUpperCase()}_${last.toUpperCase()}_${Math.floor(Math.random() * 900) + 100}`;

        const user = {
            "perfilId": role,
            "fechaCreacion": getTimestamp(),
            "fechaActualizacion": getTimestamp(),
            "authUid": 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
                var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            }),
            "email": `${first.toLowerCase()}.${last.toLowerCase()}${Math.floor(Math.random() * 99) + 1}@example.com`,
            "activo": true,
            "empresaId": EMPRESA_ID,
            "telefono": `9${Math.floor(Math.random() * 9000000) + 1000000}`,
            "nombre": name
        };

        data['usuarios'][userId] = user;
        newUsers.push(userId);
    }
    return newUsers;
}

function generateClients(data) {
    console.log("Generating clients...");
    const firstNames = ['Empresa A', 'Comercial B', 'Industrias C', 'Servicios D', 'Grupo E', 'Corporacion F', 'Asociados G', 'Hermanos H', 'Inversiones I', 'Logistica J'];
    const lastNames = ['S.A.', 'S. de R.L.', 'Inc.', 'Ltda.', 'Corp.'];

    const newClients = [];
    for (let i = 0; i < NUM_RECORDS; i++) {
        const name = `${firstNames[Math.floor(Math.random() * firstNames.length)]} ${lastNames[Math.floor(Math.random() * lastNames.length)]} ${Math.floor(Math.random() * 100) + 1}`;
        const clientId = generateId("CL", name.split(' ')[0]);

        const client = {
            "latitud": 13.3 + (Math.random() * 0.2 - 0.1),
            "empresaId": EMPRESA_ID,
            "personaContacto": `Contacto ${i}`,
            "direccion": `Direccion ${i}, Ciudad`,
            "idioma": Math.random() > 0.5 ? 'es' : 'en',
            "nombre": name,
            "creadoPor": "USR_ADMIN",
            "razonSocial": name,
            "longitud": -87.1 + (Math.random() * 0.2 - 0.1),
            "fechaCreacion": getTimestamp(),
            "fechaActualizacion": getTimestamp(),
            "telefono": `2${Math.floor(Math.random() * 9000000) + 1000000}`,
            "actualizadoPor": "USR_ADMIN",
            "email": `contacto${i}@client.com`,
            "activo": true
        };
        data['clientes'][clientId] = client;
        newClients.push(clientId);
    }
    return newClients;
}

function generateJobs(data) {
    console.log("Generating jobs...");
    const jobTypes = ['Mantenimiento', 'Reparacion', 'Instalacion', 'Revision', 'Limpieza', 'Diagnostico', 'Actualizacion'];
    const items = ['Aire Acondicionado', 'Generador', 'Computadora', 'Impresora', 'Red', 'Camaras', 'Servidor'];

    const newJobs = [];
    for (let i = 0; i < NUM_RECORDS; i++) {
        const title = `${jobTypes[Math.floor(Math.random() * jobTypes.length)]} de ${items[Math.floor(Math.random() * items.length)]} ${i}`;
        const jobId = generateId("TRB", `JOB_${i}`);

        const job = {
            "descripcion": `Descripcion detallada para ${title}`,
            "empresaId": EMPRESA_ID,
            "costo": Math.floor(Math.random() * 4900) + 100,
            "titulo": title,
            "fechaCreacion": getTimestamp(),
            "fechaActualizacion": getTimestamp(),
            "activo": true
        };
        data['trabajos'][jobId] = job;
        newJobs.push(jobId);
    }
    return newJobs;
}

function generateAssignedJobs(data, clientIds, jobIds, technicianIds) {
    console.log("Generating assigned jobs...");
    const newAssignments = [];

    // Filter technicians
    let techs = Object.keys(data['usuarios']).filter(uid => data['usuarios'][uid].perfilId === 'PERF_TEC');
    if (techs.length === 0) {
        techs = technicianIds; // Fallback
    }

    for (let i = 0; i < NUM_RECORDS; i++) {
        const clientId = clientIds[Math.floor(Math.random() * clientIds.length)];
        const jobId = jobIds[Math.floor(Math.random() * jobIds.length)];
        const assignId = `ASIG_${jobId}__${clientId}_${Date.now()}`;

        const assignment = {
            "estado": ["Pendiente", "En Progreso", "Completado"][Math.floor(Math.random() * 3)],
            "esCiclico": Math.random() > 0.5,
            "empresaId": EMPRESA_ID,
            "proximaFecha": getTimestamp(),
            "trabajoId": jobId,
            "precioFinal": Math.floor(Math.random() * 4900) + 100,
            "frecuenciaCiclico": ["mensual", "trimestral", "semestral", "anual"][Math.floor(Math.random() * 4)],
            "fechaFin": getTimestamp(),
            "creadoPor": "Administrador",
            "tecnicosAsignados": techs.length > 0 ? [techs[Math.floor(Math.random() * techs.length)]] : [],
            "clienteId": clientId,
            "fechaInicio": getTimestamp(),
            "fechaCreacion": getTimestamp(),
            "fechaActualizacion": getTimestamp(),
            "actualizadoPor": "Administrador",
            "activo": true
        };
        data['trabajosAsignados'][assignId] = assignment;
        newAssignments.push(assignId);
    }
    return newAssignments;
}

function generateActivities(data, assignmentIds) {
    console.log("Generating activities...");
    for (let i = 0; i < NUM_RECORDS; i++) {
        const assignId = assignmentIds[Math.floor(Math.random() * assignmentIds.length)];
        const assignment = data['trabajosAsignados'][assignId];
        const jobId = assignment['trabajoId'];
        const clientId = assignment['clienteId'];

        const actId = generateId("ACT", `WORK_${i}`);

        const activity = {
            "descripcion": `Actividad realizada ${i}`,
            "trabajoAsignadoId": assignId,
            "empresaId": EMPRESA_ID,
            "fechaActividad": getTimestamp(),
            "materialCostoUnitario": Math.floor(Math.random() * 90) + 10,
            "notas": `Nota de actividad ${i}`,
            "trabajoId": jobId,
            "creadoPor": "USR_ADMIN",
            "clienteId": clientId,
            "tecnicoNombre": "Tecnico Generado",
            "materialCantidad": Math.floor(Math.random() * 10) + 1,
            "tecnicoId": "USR_TECNICO",
            "horasTrabajadas": Math.floor(Math.random() * 8) + 1,
            "fechaCreacion": getTimestamp(),
            "fechaActualizacion": getTimestamp(),
            "actualizadoPor": "USR_ADMIN",
            "activo": true,
            "materialNombre": `Material ${i}`
        };
        data['actividades'][actId] = activity;
    }
}

function generateExpenses(data, assignmentIds) {
    console.log("Generating expenses...");
    for (let i = 0; i < NUM_RECORDS; i++) {
        const assignId = assignmentIds[Math.floor(Math.random() * assignmentIds.length)];
        const assignment = data['trabajosAsignados'][assignId];
        const jobId = assignment['trabajoId'];
        const clientId = assignment['clienteId'];

        const expId = generateId("GST", `EXP_${i}`);

        const expense = {
            "descripcion": `Gasto generado ${i}`,
            "trabajoAsignadoId": assignId,
            "urlComprobante": "",
            "idTipoGasto": "TG_MAT",
            "empresaId": EMPRESA_ID,
            "trabajoId": jobId,
            "fechaGasto": getTimestamp(),
            "creadoPor": "USR_ADMIN",
            "monto": Math.floor(Math.random() * 450) + 50,
            "clienteId": clientId,
            "fechaCreacion": getTimestamp(),
            "fechaActualizacion": getTimestamp(),
            "actualizadoPor": "USR_ADMIN",
            "activo": true
        };
        data['gastos'][expId] = expense;
    }
}

function generateProblems(data, assignmentIds) {
    console.log("Generating problems...");
    for (let i = 0; i < NUM_RECORDS; i++) {
        const assignId = assignmentIds[Math.floor(Math.random() * assignmentIds.length)];
        const assignment = data['trabajosAsignados'][assignId];

        const probId = generateId("PRB", `PROB_${i}`);

        const problem = {
            "descripcion": `Problema reportado ${i}`,
            "trabajoAsignadoId": assignId,
            "reportadoPorId": "USR_TECNICO",
            "empresaId": EMPRESA_ID,
            "direccion": "Direccion del problema",
            "titulo": `Fallo en sistema ${i}`,
            "fotoUrl": "",
            "creadoPorId": "USR_TECNICO",
            "fechaCreacion": getTimestamp(),
            "activo": true,
            "estado": ["pendiente", "resuelto", "en_proceso"][Math.floor(Math.random() * 3)],
            "resueltoPorId": Math.random() > 0.5 ? "USR_ADMIN" : "",
            "fechaActualizacion": getTimestamp(),
            "actualizadoPorId": "USR_ADMIN"
        };
        data['problemas'][probId] = problem;
    }
}

function main() {
    try {
        const data = loadData();

        // 1. Users
        const newUsers = generateUsers(data);

        // 2. Clients
        const newClients = generateClients(data);

        // 3. Jobs
        const newJobs = generateJobs(data);

        // 4. Assigned Jobs
        const allClients = Object.keys(data['clientes']);
        const allJobs = Object.keys(data['trabajos']);
        const allTechs = Object.keys(data['usuarios']).filter(uid => data['usuarios'][uid].perfilId === 'PERF_TEC');

        const newAssignments = generateAssignedJobs(data, allClients, allJobs, allTechs);

        // 5. Activities, Expenses, Problems
        const allAssignments = Object.keys(data['trabajosAsignados']);

        generateActivities(data, allAssignments);
        generateExpenses(data, allAssignments);
        generateProblems(data, allAssignments);

        saveData(data);
        console.log("Database populated successfully!");

    } catch (e) {
        console.error(`Error: ${e.message}`);
    }
}

main();
