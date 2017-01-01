func mkcls
     < mkcls
     < in
     > out
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	num_classes=50
	num_optimization_runs=2

	${mkcls} -c${num_classes} \
	         -n${num_optimization_runs} \
		 -p${in} \
		 -V${out} \
		 opt

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

func plain2snt
     < plain2snt
     < src_in
     < tgt_in
     > src_vcb
     > src_snt
     > tgt_vcb
     > tgt_snt
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	${plain2snt} ${src_in}        \
	             ${tgt_in}        \
	             -vcb1 ${src_vcb} \
		     -snt1 ${src_snt} \
		     -vcb2 ${tgt_vcb} \
		     -snt2 ${tgt_snt}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

func snt2cooc
     < snt2cooc
     < src_vcb
     < tgt_vcb
     < integerized_bitext
     > out
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	${snt2cooc} ${out} ${src_vcb} ${tgt_vcb} ${integerized_bitext}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

func mgiza
     < mgiza
     < merge_alignment_script
     < coocurrence_file
     < src_vcb
     < src_vcb_classes
     < tgt_vcb
     < tgt_vcb_classes
     < integerized_bitext
     :: num_cpus
     > out
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	${mgiza} -CoocurrenceFile ${coocurrence_file}        \
	         -c ${integerized_bitext}                    \
		 -model1iterations 5                         \
		 -model2iterations 0                         \
		 -hmmiterations    5                         \
		 -model3iterations 3                         \
		 -model4iterations 3                         \
		 -model5iterations 0                         \
		 -model6iterations 0                         \
		 -model1dumpfrequency 1                      \
		 -model4smoothfactor 0.4                     \
		 -ncpus ${num_cpus}                          \
		 -nodumps 1                                  \
		 -nsmooth 4                                  \
		 -o out                                      \
		 -onlyaldumps 1                              \
		 -p0 0.999                                   \
		 -s ${src_vcb}                               \
		 -t ${tgt_vcb}                               \
		 -sourcevocabularyclasses ${src_vcb_classes} \
		 -targetvocabularyclasses ${tgt_vcb_classes} 

	${merge_alignment_script} out.A3.final.part* > ${out}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

func mgiza_symmetrize
     < giza2bal
     < symal
     < mgiza_forward_alignments
     < mgiza_reverse_alignments
     > out
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	${giza2bal} -d ${mgiza_forward_alignments} -i ${mgiza_reverse_alignments} | \
	${symal} -alignment="grow" -diagonal="yes" -final="yes" -both="yes"       | \
	sed 's,.*{##} ,,' > ${out}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}
