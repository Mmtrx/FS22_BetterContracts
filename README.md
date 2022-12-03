# FS22_BetterContracts

[Download latest release](https://github.com/Mmtrx/FS22_BetterContracts/releases/latest)

Farming Simulator mod to enhance contracts handling
---
"Should I take those three fertilizer missions, or rather the 2.3 ha potato harvesting contract?" "How much liquid fertilizer will I need for this job?" If you ever asked yourself questions like these, this mod will help to find the answers. It improves the contract system, both in singleplayer and multiplayer.
- The maximum number and the amount of missions generated is automatically adjusted to the number of fields on the map.
- You can immediately generate new missions through the "New Contracts" button, or delete all of them with the "Clear Contracts" button.
- With the "Details" button you can toggle on/ off the display of additional contract information. 
- You can sort the available contracts by type and field number, by total profit, or by profit per minute, to make it easier to find the one you desire.
- You can activate more than one contract at a time.
- Contracts can be sorted to type (standard game), net profit, and profit/min
- Added some new vehicle combos for contracts
- With the "Details" button you can toggle on/ off the display of additional contract information. Like cost estimates for usage material as fertilizer, herbicide, or seeds. For harvest and baling contracts, it shows the minimum amount to be delivered, and the amount that you can keep (and sell). From this it calculates the total profit value for a contract, i.e. reward minus cost for fertilize/ spray/ sow contracts, and reward plus value of kept harvest for harvest/ baling contracts. It even estimates the time you will probably need for total completion of the job, by taking into account the work speed and work width of the appropriate leasing vehicles/ tools that are offered with the contract.

Disclaimer: All values shown in details display are ESTIMATES. You should not take them absolutely, but rather as an indication of what contracts to prefer among others.

**Changelog**:
Version | Date | Description
---|---|---
v1.2.6.0 |30.11.2022|UI for all settings
v1.2.5.0 |31.10.2022|Hard mode: active missions time out at month end. Penalty for mission cancel. Discount mode: get discounted field price, based on # of missions. Mission vehicle warnings: only if no vehicles or debug="true"
v1.2.4.4 |16.10.2022|fix FS22_LimeMission details, filter buttons. Add timeLeft to MP sync
|        |21.10.2022|fix mtype.LIME, FS22_IBCtankfix mod compat
v1.2.4.3 |10.10.2022|recognize FS22_LimeMission, RollerMission. Add lazyNPC switch for weed. Delete config.xml file template from mod directory

 v1.2.4.2:
- "lazy NPCs" (leave more work for contracts) can be configured on/ off
- maximum number of active contracts configurable (in modSettings/FS22_BetterContracts.xml)
- indicator for active contracts with borrowed equipment 
- clear / new contracts buttons in MP games only work for master user
- recognize FS22_DynamicMissionVehicles

Changelog v1.2.4.0:
- Added (interim) fix for "lazy NPCs": leave more work for contracts
- Allow for (future) other contract types 
- Fixed screen resolution issues

Changelog v1.2.3.0:
- Added display filter function for contracts list 

Changelog v1.2.2.0:
- Adjusted calculation of keep / deliver values for harvest / baling contracts
- Added conflicts prevention with other mods
- Added support for FS22_SupplyTransportContracts, FS22_TransportMissions
---
![iconfinder_flag-germany_748067](https://user-images.githubusercontent.com/7534621/114938948-08f06580-9e40-11eb-9bd9-cd9733f1c6bc.png)  
"Mach ich jetzt diese drei Düngemissionen, oder doch lieber den 2.3 ha Kartoffelernte-Vertrag?" "Wieviel Flüssigdünger brauche ich für diesen Auftrag?" Falls Sie sich je derartige Fragen gestellt haben, hilft Ihnen dieser Mod bei den Antworten. Er verbessert das Vertragsmanagement, sowohl im Einzelspieler- als im Multiplayer-Modus.
- Die Maximalzahl sowie die Anzahl der jeweils neu generierten Missionen werden automatisch an die Zahl der Felder auf der Karte angepasst.
- Sie können über die Schaltfläche "Neue Verträge" sofort neue Missionen generieren oder alle mit dem Button "Liste löschen" entfernen.
- Mit dem "Details" Button kann die Anzeige der zusätzlichen Vertragsdetails ein- und ausgeschaltet werden.
- Sie können die Vertragsliste sortieren nach Vertragstyp/ Feldnummer, nach Gesamtprofit, und nach Profit pro Minute, um einen gewünschten Vertrag schnell zu finden.
- Sie können mehr als einen Vertrag gleichzeitig aktivieren.
- Es wurden neue Fahrzeugkombinationen für Verträge hinzugefügt
- Mit dem "Details" Button kann die Anzeige der zusätzlichen Vertragsdetails ein- und ausgeschaltet werden. Z.B. die geschätzten Kosten des Verbrauchsmaterials (Dünger, Pflanzenschutzmittel, Saatgut). Bei Ernte- und Gras-Missionen wird die abzuliefernde Mindestmenge angezeigt, sowie die Erntemenge, die Sie behalten (und verkaufen) können. Daraus ermittelt der Mod den Gesamtertrag der Mission, also Belohnung minus Kosten für Dünge-, Spritz-, und Sähen-Verträge; und Belohnung plus Wert der behaltenen Erntemenge bei den Ernte- und Gras-Verträgen. Er schätzt sogar die Gesamtzeit, die Sie für die Erledigung des Auftrags benötigen werden, und berücksichtigt dafür Arbeitsgeschwindigkeit und Arbeitsbreite der entsprechenden Leasing-Geräte, die für den Vertrag angeboten werden.

Warnung: Alle in der Detailanzeige angegebenen Werte sind GESCHÄTZT. Sie sollten sie also nicht als absolute Zahlen verstehen, sondern als Hinweis, welche Verträge vielleicht anderen vorzuziehen sind.

Changelog v1.2.4.2:
- "Faule NPCs" (mehr Feldarbeit für Verträge) kann konfiguriert werden
- Maximalzahl gleichzeitig aktiver Verträge kann konfiguriert werden (in modSettings/FS22_BetterContracts.xml)
- Kennzeichnung aktiver Verträge mit Leihgeräten 
- In Multiplayer-Spielen sind die Buttons "Neue Verträge" und "Liste löschen" nur für Administratoren aktiv
- Mod-Erkennung FS22_DynamicMissionVehicles

Changelog v1.2.4.0:
- Temporärer Fix "Faule NPCs": Mehr (Ernte-)Verträge verfügbar
- Weitere Vertragstypen möglich 
- Probleme mit verschiedenen Bildschirmformaten behoben 

Changelog v1.2.3.0:
- Anzeigefilter für die Vertragsliste hinzugefügt 

Changelog v1.2.2.0:
- Berechnung der Mindestliefer- und Eigenmengen angepasst bei Ernte- und Gras-Verträgen
- Konfliktvermeidung mit anderen Mods
- Unterstützung für FS22_SupplyTransportContracts, FS22_TransportMissions
