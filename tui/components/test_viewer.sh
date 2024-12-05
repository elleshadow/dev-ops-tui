#!/bin/bash

# Source required modules
source "$(dirname "${BASH_SOURCE[0]}")/../theme.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/db.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/logging.sh"

# Show test runs menu
show_test_runs_menu() {
    while true; do
        # Get list of test runs
        local runs
        runs=$(sqlite3 "$DB_PATH" "SELECT run_id || ' (' || 
            strftime('%Y-%m-%d %H:%M:%S', started_at) || ') - ' ||
            passed_tests || '/' || total_tests || ' passed'
            FROM test_runs ORDER BY started_at DESC LIMIT 20;")
        
        local run_list=()
        while IFS= read -r run; do
            run_list+=("$run" "")
        done <<< "$runs"
        
        local choice
        choice=$(dialog --clear --title "Test Results" \
            --menu "Select test run to view:" \
            20 70 10 \
            "${run_list[@]}" \
            "BACK" "Return to main menu" \
            2>&1 >/dev/tty)
        
        case $choice in
            "BACK") break ;;
            *)
                local run_id
                run_id=$(echo "$choice" | cut -d' ' -f1)
                show_test_run_details "$run_id"
                ;;
        esac
    done
}

# Show test run details
show_test_run_details() {
    local run_id="$1"
    
    while true; do
        local choice
        choice=$(dialog --clear --title "Test Run Details - $run_id" \
            --menu "Select view:" \
            15 60 5 \
            "1" "Summary" \
            "2" "Test Results" \
            "3" "Coverage Report" \
            "4" "Export Results" \
            "5" "Back" \
            2>&1 >/dev/tty)
        
        case $choice in
            1) show_test_summary "$run_id" ;;
            2) show_test_results "$run_id" ;;
            3) show_coverage_report "$run_id" ;;
            4) export_test_results "$run_id" ;;
            5) break ;;
            *) continue ;;
        esac
    done
}

# Show test summary
show_test_summary() {
    local run_id="$1"
    local summary
    summary=$(get_test_run_summary "$run_id")
    
    local total passed failed duration
    total=$(echo "$summary" | jq -r '.total_tests')
    passed=$(echo "$summary" | jq -r '.passed_tests')
    failed=$(echo "$summary" | jq -r '.failed_tests')
    duration=$(echo "$summary" | jq -r '.duration_ms')
    
    local message="Test Run: $run_id\n\n"
    message+="Started: $(echo "$summary" | jq -r '.started_at')\n"
    message+="Completed: $(echo "$summary" | jq -r '.completed_at')\n\n"
    message+="Total Tests: $total\n"
    message+="Passed: $passed\n"
    message+="Failed: $failed\n"
    message+="Duration: $(($duration / 1000)) seconds\n\n"
    message+="Pass Rate: $(( (passed * 100) / total ))%"
    
    dialog --title "Test Summary" \
        --msgbox "$message" \
        20 60
}

# Show test results
show_test_results() {
    local run_id="$1"
    local results
    results=$(get_test_results "$run_id")
    
    local message=""
    local total_duration=0
    local count=0
    
    while read -r result; do
        local suite test status duration error
        suite=$(echo "$result" | jq -r '.suite')
        test=$(echo "$result" | jq -r '.test')
        status=$(echo "$result" | jq -r '.status')
        duration=$(echo "$result" | jq -r '.duration_ms')
        error=$(echo "$result" | jq -r '.error_message')
        
        ((count++))
        ((total_duration += duration))
        
        message+="$count. $suite::$test\n"
        message+="   Status: $status\n"
        message+="   Duration: $(($duration / 1000)) seconds\n"
        [[ -n "$error" && "$error" != "null" ]] && message+="   Error: $error\n"
        message+="\n"
    done < <(echo "$results" | jq -c '.[]')
    
    message+="\nTotal Duration: $(($total_duration / 1000)) seconds"
    
    dialog --title "Test Results" \
        --msgbox "$message" \
        25 70
}

# Show coverage report
show_coverage_report() {
    local run_id="$1"
    local coverage
    coverage=$(get_test_coverage "$run_id")
    
    local message="Coverage Report\n\n"
    local total_coverage=0
    local file_count=0
    
    while read -r file_coverage; do
        local file coverage_pct uncovered
        file=$(echo "$file_coverage" | jq -r '.file')
        coverage_pct=$(echo "$file_coverage" | jq -r '.coverage')
        uncovered=$(echo "$file_coverage" | jq -r '.uncovered')
        
        ((file_count++))
        total_coverage=$(echo "$total_coverage + $coverage_pct" | bc)
        
        message+="$file: $coverage_pct%\n"
        [[ -n "$uncovered" && "$uncovered" != "null" ]] && \
            message+="   Uncovered lines: $uncovered\n"
        message+="\n"
    done < <(echo "$coverage" | jq -c '.[]')
    
    [[ $file_count -gt 0 ]] && \
        message+="\nAverage Coverage: $(echo "scale=2; $total_coverage / $file_count" | bc)%"
    
    dialog --title "Coverage Report" \
        --msgbox "$message" \
        25 70
}

# Export test results
export_test_results() {
    local run_id="$1"
    local export_dir="$HOME/test_results"
    mkdir -p "$export_dir"
    
    local filename="$export_dir/test_results_${run_id}.json"
    
    # Combine all data
    local data
    data=$(sqlite3 "$DB_PATH" "SELECT json_object(
        'run_id', run_id,
        'started_at', started_at,
        'completed_at', completed_at,
        'total_tests', total_tests,
        'passed_tests', passed_tests,
        'failed_tests', failed_tests,
        'duration_ms', duration_ms,
        'results', (
            SELECT json_group_array(json_object(
                'suite', test_suite,
                'test', test_name,
                'status', status,
                'duration_ms', duration_ms,
                'error_message', error_message,
                'stack_trace', stack_trace
            ))
            FROM test_results
            WHERE test_results.run_id = test_runs.run_id
        ),
        'coverage', (
            SELECT json_group_array(json_object(
                'file', file_path,
                'total_lines', total_lines,
                'covered_lines', covered_lines,
                'coverage_percent', coverage_percent,
                'uncovered_lines', uncovered_lines
            ))
            FROM test_coverage
            WHERE test_coverage.run_id = test_runs.run_id
        )
    ) FROM test_runs WHERE run_id='$run_id';")
    
    echo "$data" > "$filename"
    
    dialog --title "Export Complete" \
        --msgbox "Test results exported to:\n$filename" \
        8 60
}

# Export functions
export -f show_test_runs_menu
export -f show_test_run_details
export -f show_test_summary
export -f show_test_results
export -f show_coverage_report
export -f export_test_results 