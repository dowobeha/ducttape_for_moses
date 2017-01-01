func lmplz
     < lmplz
     < corpus
     :: max_ngram_order
     > arpa_file
     :: max_sorting_memory
     :: tmp_dir
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	set -o xtrace

	${lmplz}                          \
	   --text  ${corpus}              \
	   --order ${max_ngram_order}     \
	   --arpa  ${arpa_file}           \
	   --prune 0 0 1                  \
	   --temp_prefix ${tmp_dir}       \
	   --memory ${max_sorting_memory} \

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}


func build_binary
     < build_binary
     < arpa_file
     > out
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	${build_binary} ${arpa_file} ${out}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}
