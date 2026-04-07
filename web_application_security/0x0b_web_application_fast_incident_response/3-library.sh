#!/bin/bash

# Attacker User-Agent tapmaq üçün logs.txt faylını analiz edir
# Hər hansı IP və ya filter istifadə etmədən bütün User-Agentləri sayır

# Log faylından User-Agentləri çıxarır, sayır və ən çox istifadə olunanı göstərir
grep -o '\".*\"$' logs.txt | awk -F'"' '{print $(NF-1)}' | sort | uniq -c | sort -nr | head -n1 | awk '{print $2}'
