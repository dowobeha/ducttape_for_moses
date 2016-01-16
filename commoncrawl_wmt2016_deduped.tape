
task commoncrawl_wmt2016_deduped
     < tools_tarball="/projects/cl/data/Buck_et_al_2014_LREC_prepro.tgz"
     < tokenizer="/projects/cl/local/moses-v3/scripts/tokenizer/tokenizer.perl"
     < lowercaser="/projects/cl/local/moses-v3/scripts/tokenizer/lowercase.perl"
     < data_xz="/projects/cl/data/commoncrawl_wmt2016_deduped.en.xz"
     > out
{

	tar --extract --verbose --gzip --file="${tools_tarball}" --strip-components=1

	cat prepro_post_dedupe_en.sh | grep -v unescape_html > clean.sh
	chmod u+x clean.sh

	date
	xz --decompress --stdout --keep --verbose ${data_xz} > ${out}
# | ./clean.sh > ${out}
#| ${tokenizer} | ${lowercaser} > ${out}
	date

}
