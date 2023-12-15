"""
    path = choose_besc_output_dir(pathinit)

Avoid overwriting (potentially important) existing results by appending to the directory name\n
Checks if the suggested output directory already exists. While yes, it appends _1, _2, etc till an unused name is found
"""
function choose_besc_output_dir(pathinit::String)
    path = joinpath(pathinit, "Results_BESC")
    counter = 1
    while isdir(path)
        path = joinpath(string(pathinit, "_", counter), "Results_BESC")
        counter += 1
    end
    return path
end
