#!/bin/bash
set -e
PATH_COVERAGE=$1

main() {
    cleanTesting()
    coveragePercentage()
    return getCommentBody()
}

coveragePercentage() {
    printf "extracting coverage percentage..."
    MIN_COVERAGE_PERC=0

    percentageRate=$(lcov --summary "$PATH_COVERAGE" | grep "lines......" | cut -d ' ' -f 4 | cut -d '%' -f 1)

    RED='\033[0;31m'
    GREEN='\033[0;32m'

    if [ "$(echo "${percentageRate} < $MIN_COVERAGE_PERC" | bc)" -eq 1 ]; then
        printf "${RED}Error: Your coverage rate is too low, expected ${MIN_COVERAGE_PERC}% but have ${percentageRate}%.\n"
        printf "${RED}Please add more tests to cover your code.\n"
        printf "${RED}To see in local your coverage rate use:\n"
        printf "${RED}    sh scripts/create_clean_lcov_and_generate_html.sh true\n"
        exit 1
    else
        printf "${GREEN}Coverage rate is fine with ${percentageRate}% coverage 👍. Build continue...\n"
    fi
}

cleanTesting() {
    printf "extracting lcov file..."
    file=test/coverage_helper_test.dart
    find lib -name '*_view_model_impl.dart' |awk -v package="$1" '{printf "import '\''package:%s%s'\'';\n", package, $1}' >> $file
    echo 'void main() {}' >> $file
    
    flutter test --coverage
    lcov --extract coverage/lcov.info 'lib/src/*_view_model_impl.dart' -o coverage/lcov.info
    genhtml coverage/lcov.info -o coverage/html -t ${PWD##*/}
    open coverage/html/index.html
    rm test/coverage_helper_test.dart
}

getCommentBody() {
    printf "extracting text for comment body..."
    body="$(cat coverage/coverage.txt)"
    body="${body//'%'/'%25'}"
    body="${body//$'\n'/'%0A'}"
    body="${body//$'\r'/'%0D'}"
    echo "::set-output name=body::$body" 
}

main()
