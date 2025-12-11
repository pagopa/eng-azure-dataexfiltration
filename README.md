# eng-azure-dataexfiltration

---
## Repository Structure & Details (Auto-generated)

### Scopo
Analogo controllo traffico su Azure con listener SNI, firewall e DNS resolver per ridurre il rischio di esfiltrazione dati; integra firewalling e logging centralizzato.

### Cartelle
- `sni-listener/`: `sni-listener.go` per logging SNI.
- `infra/`: Terraform per VNet, Azure Firewall, DNS resolver/forwarder, VM/FunctionApp listener, VPN, storage/monitoring.

### Script
- `sni-listener/sni-listener.go`: server TLS per logging SNI.

### Workflow
Nessuno.

### Note
Richiede configurazioni DNS/VPN coerenti con il design di rete; coordinare con team network.
