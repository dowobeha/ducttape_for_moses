func lmplz
     < lmplz
     < corpus
     :: max_ngram_order
     > arpa_file
     :: max_sorting_memory
     :: tmp_dir
{

	set -o xtrace

	${lmplz}                          \
	   --text  ${corpus}              \
	   --order ${max_ngram_order}     \
	   --arpa  ${arpa_file}           \
	   --prune 0 0 1                  \
	   --temp_prefix ${tmp_dir}       \
	   --memory ${max_sorting_memory} \

}


func build_binary
     < build_binary
     < arpa_file
     > out
{
	${build_binary} ${arpa_file} ${out}
}
