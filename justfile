set windows-shell := ["sh", "-cu"]

gobo := env("GOBO")
exe := if os() == "windows" { ".exe" } else { "" }

default:
    @just --list

generate-tests:
    "{{ gobo }}/bin/getest{{ exe }}" -g tests/getest.cfg

test-gobo: generate-tests
    GOBO_EIFFEL=ge "{{ gobo }}/bin/gec{{ exe }}" --variable=GOBO_EIFFEL=ge --ise=25.02 --gelint --target=shablon_tests shablon.ecf
    SHABLON_ASSERTIONS=on ./shablon_tests{{ exe }}

test-ise: generate-tests
    GOBO_EIFFEL=ise ec -batch -config shablon.ecf -target shablon_tests -c_compile
    SHABLON_ASSERTIONS=on ./EIFGENs/shablon_tests/W_code/shablon_tests{{ exe }}

test-gobo-no-assertions: generate-tests
    GOBO_EIFFEL=ge "{{ gobo }}/bin/gec{{ exe }}" --variable=GOBO_EIFFEL=ge --ise=25.02 --gelint --target=shablon_tests_no_assertions shablon.ecf
    SHABLON_ASSERTIONS=off ./shablon_tests_no_assertions{{ exe }}

test-ise-no-assertions: generate-tests
    GOBO_EIFFEL=ise ec -batch -config shablon.ecf -target shablon_tests_no_assertions -c_compile
    SHABLON_ASSERTIONS=off ./EIFGENs/shablon_tests_no_assertions/W_code/shablon_tests_no_assertions{{ exe }}

test: test-gobo test-ise test-gobo-no-assertions test-ise-no-assertions

example-gobo:
    GOBO_EIFFEL=ge "{{ gobo }}/bin/gec{{ exe }}" --variable=GOBO_EIFFEL=ge --ise=25.02 --gelint --target=demo examples/demo/demo.ecf
    ./shablon_demo{{ exe }}

example-ise:
    GOBO_EIFFEL=ise ec -batch -config examples/demo/demo.ecf -target demo -c_compile
    ./EIFGENs/demo/W_code/shablon_demo{{ exe }}

example: example-gobo

format:
    for source in src/*.e tests/*.e examples/*/*.e; do (cd "$(dirname "$source")" && GOBO_EIFFEL=ge "{{ gobo }}/bin/gedoc{{ exe }}" --silent --force "$(basename "$source")") || exit; done
