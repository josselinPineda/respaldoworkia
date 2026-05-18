import json
import random
import time
import uuid

# Configuration
BACKUP_FILE = 'h:\\allan\\Proyectos\\Flutter\\workia\\backupFileFull.json'
EMPRESA_ID = 'EMP_SERVICIOS_DEMO'
NUM_RECORDS = 15

def get_timestamp():
    now = time.time()
    seconds = int(now)
    nanoseconds = int((now - seconds) * 1e9)
    return {
        "__type__": "timestamp",
        "_seconds": seconds,
        "_nanoseconds": nanoseconds
    }

def generate_id(prefix, name=None):
    timestamp = int(time.time() * 1000)
    if name:
        clean_name = name.upper().replace(' ', '_')
        return f"{prefix}_{clean_name}_{timestamp}"
    return f"{prefix}_{timestamp}_{random.randint(1000, 9999)}"

def load_data():
    with open(BACKUP_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_data(data):
    with open(BACKUP_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def generate_users(data):
    print("Generating users...")
    roles = ['PERF_TEC', 'PERF_ADMIN', 'PERF_FIN']
    first_names = ['Juan', 'Maria', 'Pedro', 'Ana', 'Luis', 'Sofia', 'Carlos', 'Lucia', 'Miguel', 'Elena', 'Roberto', 'Patricia', 'David', 'Carmen', 'Jose']
    last_names = ['Perez', 'Gomez', 'Rodriguez', 'Lopez', 'Martinez', 'Sanchez', 'Garcia', 'Fernandez', 'Gonzalez', 'Diaz', 'Vasquez', 'Castro', 'Ruiz', 'Jimenez', 'Torres']
    
    new_users = []
    for i in range(NUM_RECORDS):
        first = random.choice(first_names)
        last = random.choice(last_names)
        name = f"{first} {last}"
        role = random.choice(roles)
        user_id = f"USR_{first.upper()}_{last.upper()}_{random.randint(100,999)}"
        
        user = {
            "perfilId": role,
            "fechaCreacion": get_timestamp(),
            "fechaActualizacion": get_timestamp(),
            "authUid": str(uuid.uuid4()),
            "email": f"{first.lower()}.{last.lower()}{random.randint(1,99)}@example.com",
            "activo": True,
            "empresaId": EMPRESA_ID,
            "telefono": f"9{random.randint(1000000, 9999999)}",
            "nombre": name
        }
        
        if role == 'PERF_TEC':
             # Ensure we have technicians for assignments
             pass

        data['usuarios'][user_id] = user
        new_users.append(user_id)
    return new_users

def generate_clients(data):
    print("Generating clients...")
    first_names = ['Empresa A', 'Comercial B', 'Industrias C', 'Servicios D', 'Grupo E', 'Corporacion F', 'Asociados G', 'Hermanos H', 'Inversiones I', 'Logistica J']
    last_names = ['S.A.', 'S. de R.L.', 'Inc.', 'Ltda.', 'Corp.']
    
    new_clients = []
    for i in range(NUM_RECORDS):
        name = f"{random.choice(first_names)} {random.choice(last_names)} {random.randint(1, 100)}"
        client_id = generate_id("CL", name.split()[0])
        
        client = {
            "latitud": 13.3 + random.uniform(-0.1, 0.1),
            "empresaId": EMPRESA_ID,
            "personaContacto": f"Contacto {i}",
            "direccion": f"Direccion {i}, Ciudad",
            "idioma": random.choice(['es', 'en']),
            "nombre": name,
            "creadoPor": "USR_ADMIN",
            "razonSocial": name,
            "longitud": -87.1 + random.uniform(-0.1, 0.1),
            "fechaCreacion": get_timestamp(),
            "fechaActualizacion": get_timestamp(),
            "telefono": f"2{random.randint(1000000, 9999999)}",
            "actualizadoPor": "USR_ADMIN",
            "email": f"contacto{i}@client.com",
            "activo": True
        }
        data['clientes'][client_id] = client
        new_clients.append(client_id)
    return new_clients

def generate_jobs(data):
    print("Generating jobs...")
    job_types = ['Mantenimiento', 'Reparacion', 'Instalacion', 'Revision', 'Limpieza', 'Diagnostico', 'Actualizacion']
    items = ['Aire Acondicionado', 'Generador', 'Computadora', 'Impresora', 'Red', 'Camaras', 'Servidor']
    
    new_jobs = []
    for i in range(NUM_RECORDS):
        title = f"{random.choice(job_types)} de {random.choice(items)} {i}"
        job_id = generate_id("TRB", f"JOB_{i}")
        
        job = {
            "descripcion": f"Descripcion detallada para {title}",
            "empresaId": EMPRESA_ID,
            "costo": random.randint(100, 5000),
            "titulo": title,
            "fechaCreacion": get_timestamp(),
            "fechaActualizacion": get_timestamp(),
            "activo": True
        }
        data['trabajos'][job_id] = job
        new_jobs.append(job_id)
    return new_jobs

def generate_assigned_jobs(data, client_ids, job_ids, technician_ids):
    print("Generating assigned jobs...")
    new_assignments = []
    
    # Filter technicians
    techs = [uid for uid, u in data['usuarios'].items() if u.get('perfilId') == 'PERF_TEC']
    if not techs:
        techs = technician_ids # Fallback if no existing techs
    
    for i in range(NUM_RECORDS):
        client_id = random.choice(client_ids)
        job_id = random.choice(job_ids)
        assign_id = f"ASIG_{job_id}__{client_id}_{int(time.time()*1000)}"
        
        assignment = {
            "estado": random.choice(["Pendiente", "En Progreso", "Completado"]),
            "esCiclico": random.choice([True, False]),
            "empresaId": EMPRESA_ID,
            "proximaFecha": get_timestamp(), # Should be future ideally
            "trabajoId": job_id,
            "precioFinal": random.randint(100, 5000),
            "frecuenciaCiclico": random.choice(["mensual", "trimestral", "semestral", "anual"]),
            "fechaFin": get_timestamp(),
            "creadoPor": "Administrador",
            "tecnicosAsignados": random.sample(techs, k=min(len(techs), random.randint(1, 2))) if techs else [],
            "clienteId": client_id,
            "fechaInicio": get_timestamp(),
            "fechaCreacion": get_timestamp(),
            "fechaActualizacion": get_timestamp(),
            "actualizadoPor": "Administrador",
            "activo": True
        }
        data['trabajosAsignados'][assign_id] = assignment
        new_assignments.append(assign_id)
    return new_assignments

def generate_activities(data, assignment_ids):
    print("Generating activities...")
    for i in range(NUM_RECORDS):
        assign_id = random.choice(assignment_ids)
        assignment = data['trabajosAsignados'][assign_id]
        job_id = assignment['trabajoId']
        client_id = assignment['clienteId']
        
        act_id = generate_id("ACT", f"WORK_{i}")
        
        activity = {
            "descripcion": f"Actividad realizada {i}",
            "trabajoAsignadoId": assign_id,
            "empresaId": EMPRESA_ID,
            "fechaActividad": get_timestamp(),
            "materialCostoUnitario": random.randint(10, 100),
            "notas": f"Nota de actividad {i}",
            "trabajoId": job_id,
            "creadoPor": "USR_ADMIN",
            "clienteId": client_id,
            "tecnicoNombre": "Tecnico Generado",
            "materialCantidad": random.randint(1, 10),
            "tecnicoId": "USR_TECNICO", # Simplified
            "horasTrabajadas": random.randint(1, 8),
            "fechaCreacion": get_timestamp(),
            "fechaActualizacion": get_timestamp(),
            "actualizadoPor": "USR_ADMIN",
            "activo": True,
            "materialNombre": f"Material {i}"
        }
        data['actividades'][act_id] = activity

def generate_expenses(data, assignment_ids):
    print("Generating expenses...")
    for i in range(NUM_RECORDS):
        assign_id = random.choice(assignment_ids)
        assignment = data['trabajosAsignados'][assign_id]
        job_id = assignment['trabajoId']
        client_id = assignment['clienteId']
        
        exp_id = generate_id("GST", f"EXP_{i}")
        
        expense = {
            "descripcion": f"Gasto generado {i}",
            "trabajoAsignadoId": assign_id,
            "urlComprobante": "",
            "idTipoGasto": "TG_MAT",
            "empresaId": EMPRESA_ID,
            "trabajoId": job_id,
            "fechaGasto": get_timestamp(),
            "creadoPor": "USR_ADMIN",
            "monto": random.randint(50, 500),
            "clienteId": client_id,
            "fechaCreacion": get_timestamp(),
            "fechaActualizacion": get_timestamp(),
            "actualizadoPor": "USR_ADMIN",
            "activo": True
        }
        data['gastos'][exp_id] = expense

def generate_problems(data, assignment_ids):
    print("Generating problems...")
    for i in range(NUM_RECORDS):
        assign_id = random.choice(assignment_ids)
        assignment = data['trabajosAsignados'][assign_id]
        
        prob_id = generate_id("PRB", f"PROB_{i}")
        
        problem = {
            "descripcion": f"Problema reportado {i}",
            "trabajoAsignadoId": assign_id,
            "reportadoPorId": "USR_TECNICO",
            "empresaId": EMPRESA_ID,
            "direccion": "Direccion del problema",
            "titulo": f"Fallo en sistema {i}",
            "fotoUrl": "",
            "creadoPorId": "USR_TECNICO",
            "fechaCreacion": get_timestamp(),
            "activo": True,
            "estado": random.choice(["pendiente", "resuelto", "en_proceso"]),
            "resueltoPorId": "USR_ADMIN" if random.choice([True, False]) else "",
            "fechaActualizacion": get_timestamp(),
            "actualizadoPorId": "USR_ADMIN"
        }
        data['problemas'][prob_id] = problem

def main():
    try:
        data = load_data()
        
        # 1. Users
        new_users = generate_users(data)
        
        # 2. Clients
        new_clients = generate_clients(data)
        
        # 3. Jobs
        new_jobs = generate_jobs(data)
        
        # 4. Assigned Jobs (needs clients, jobs, techs)
        # Collect all valid IDs including old ones
        all_clients = list(data['clientes'].keys())
        all_jobs = list(data['trabajos'].keys())
        all_techs = [uid for uid, u in data['usuarios'].items() if u.get('perfilId') == 'PERF_TEC']
        
        new_assignments = generate_assigned_jobs(data, all_clients, all_jobs, all_techs)
        
        # 5. Activities, Expenses, Problems (need assignments)
        all_assignments = list(data['trabajosAsignados'].keys())
        
        generate_activities(data, all_assignments)
        generate_expenses(data, all_assignments)
        generate_problems(data, all_assignments)
        
        save_data(data)
        print("Database populated successfully!")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
