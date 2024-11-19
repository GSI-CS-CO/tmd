# TMD

Timing Monitoring Dashboards (TMD) for Grafana

The status of the GSI Timing networks are monitored by two tools, Icinga and argus (custom), and visualized in Grafana/Graphite.

## Applicable Dashboards

Following dashboards are available in 'dashboards/TOS/General' folder:

* **GMT_Data_Master_Network_PRO**: Production network statistics
  * Datamaster TX message rates, Hz
    * SIS + HEST (cpu0)
    * CRYRING (cpu1)
    * ESR (cpu2)
  * Datamaster WR sync status (100%=locked)
  * TX and RX packet rates of the Localmaster WRS, Hz
  * Number of the total and late timing messages
  * Minimum and average time budgets (diff between deadline and actual time)
* **GMT_Diagnostic_PRO_INT_DEV_UNI**: Statistics from all other timing networks
  * Number of the total and late timing messages
  * Minimum and average time budgets
  * WR sync status of the diagnostics SCUs
  * Offsets between the WR and local system time (diagnostics SCUs)
* **GMT_Gateways_Snooper_PRO**: Gateway and snooper SCU statistics
  * Gateway (SIS, ESR) event rates, Hz
  * Gateway eCPU stalls
  * Gateway WR sync status (100%=locked)
  * Number of the total, late, early and overflow messages
* **GMT_UNILAC**: UNILAC network statistics
  * PZ TX message rate, Hz
  * PZ WR sync status
  * PZ cycles and warnings
  * TX and RX packet rates of the Localmaster WRS, Hz
  * Number of total and late timing messages
  * Minimum and average time budgets
* **GMT_WRS_Icinga**: WR switch statistics
  * TX packet rate of the Service WRS, packets/s
    * txf.X - transmitted frame rate, frames/s
    * wriX  - transmitted amount of data (seen by ARM CPU)
  * FPGA temperature (groupped by building:racks, network)
    * BG2: R54, R56
    * LSB6: R1
    * production, UNILAC
* **GMT_Alerts**: Alert list

## Import Dashboards into Grafana (GUI method)

```
Dashboards -> Manage -> Import -> Upload JSON File (select JSON)
```
