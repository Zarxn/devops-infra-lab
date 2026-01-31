import os

script_dir = os.path.dirname(__file__)
base_dir = os.path.join(script_dir, "..")

directories = {
    "Terraform Modules": os.path.join(base_dir, "terraform/modules/"),
    "Ansible Roles": os.path.join(base_dir, "ansible/roles/")
}

class TerraformModule:
    def __init__(self, name, variables, outputs):
        self.name = name
        self.variables = variables
        self.outputs = outputs

class AnsibleRole:
    def __init__(self, name, tasks):
        self.name = name
        self.tasks = tasks

class NonExistingOutputsFileError(Exception):
   def __init__(self, message):
       self.message = message
       super().__init__(self.message)

def get_paths(directory_key):
    items = []
    root_dir = directories[directory_key]
    for item in os.listdir(root_dir):
        module_path = os.path.join(root_dir, item)
        if os.path.isdir(module_path):
            items.append(module_path)
    return items

def get_terraform_modules_info(modules):
    terraform_modules = []
    for module in modules:
        with open(os.path.join(module, "variables.tf")) as variables_file:
            content = variables_file.read()
            variables = content.count("variable")
        try:
            with open(os.path.join(module, "outputs.tf")) as outputs_file:
                content = outputs_file.read()
                outputs = content.count("output")
        except FileNotFoundError:
            outputs = 0
        terraform_modules.append(TerraformModule(os.path.basename(module), variables, outputs))
    return terraform_modules

def get_ansible_roles_info(roles):
    ansible_roles = []
    for role in roles:
        tasks = os.listdir(os.path.join(role,"tasks"))
        ansible_roles.append(AnsibleRole(os.path.basename(role), tasks))
    return ansible_roles

def write_readme(ansible_roles, terraform_modules):
    with open('inventory.md', 'w') as readme_file:
        readme_file.write("# Infraestructure Inventory\n")
        readme_file.write("## Terraform Modules\n")
        readme_file.write("| Module | Variables | Outputs |\n")
        readme_file.write("| ------ | --------- | ------- |\n")
        for module in terraform_modules:
            readme_file.write("| {name} | {variables} | {outputs} |\n".format(name=module.name, variables=module.variables, outputs=module.outputs))
        readme_file.write("## Ansible Roles\n")
        for role in ansible_roles:
            readme_file.write("### {name}\n".format(name=role.name))
            for task in role.tasks:
              readme_file.write("- {task}\n".format(task=task))


tf_modules_paths = get_paths("Terraform Modules")
#print(tf_modules_paths)
ansible_roles_paths = get_paths("Ansible Roles")
#print(ansible_roles_paths)
terraform_modules = get_terraform_modules_info(tf_modules_paths)
ansible_roles = get_ansible_roles_info(ansible_roles_paths)

# print("=== Terraform Modules ===")
# for module in terraform_modules:
#     print("-", module.name, "(variables: {variables}, outputs: {outputs})".format(variables=module.variables, outputs=module.outputs))

# print("=== Ansible Roles ===")
# for role in ansible_roles:
#     print ("Role:", role.name)
#     for task in role.tasks:
#         print("- Task:", task)

write_readme(ansible_roles, terraform_modules)
