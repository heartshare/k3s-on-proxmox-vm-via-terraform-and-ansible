#Resources I used to build this terraform plan
#https://blog.klauke-enterprises.com/proxmox-terraform-infrastructure-as-code-leicht-gemacht
#https://www.terraform.io/docs/language/providers/configuration.html
#https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
#https://vectops.com/2020/01/provision-proxmox-vms-with-ansible-quick-and-easy/
#https://superuser.com/questions/437330/how-do-you-add-a-certificate-authority-ca-to-ubuntu#719047
#https://pve.proxmox.com/wiki/Cloud-Init_Support
#https://registry.terraform.io/modules/sdhibit/cloud-init-vm/proxmox/latest/examples/ubuntu_single_vm

terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.7.0"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.0.105:8006/api2/json" # change to your node here
  pm_password = "PASSWORD" # change to your password here
  pm_user = "root@pam"
}

variable "ssh_pub_key" {
  description = "The Public Key used for provisioned VMs using Cloud-Init"
  type = string
  default = "SSH PUBLIC KEY" #Place your SSH Public key here
}

#  
resource "proxmox_vm_qemu" "proxmox_vm" {
  count = 2
  name = "k3s-vm-${count.index}"
  target_node = "NODENAME" #change to your node name here
  clone = "VM 9000"
  os_type = "cloud-init"
  cores = 2
  agent = 1
  sockets = "1"
  cpu = "host"
  pool = "ansible_ubuntu"
  memory = 2048
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  nameserver = "192.168.0.166"
  disk {
    size = "8G"
    type = "scsi"
    storage = "zfs"
  }
  network {
    model = "virtio"
    bridge = "vmbr0"
  }
  ipconfig0 = "ip=192.168.0.20${count.index}/24,gw=192.168.0.1"
  sshkeys = <<EOF
  ${var.ssh_pub_key}
  EOF

  provisioner "local-exec" {
      command = "sleep 30 && ansible-playbook ./ansible-playbook-install-k3s.yml -i ${self.default_ipv4_address},"
  }
}
