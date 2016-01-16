
task normalizer
     < tarball="/projects/cl/data/Buck_et_al_2014_LREC_prepro.tgz"
     > en_script="prepro_post_dedupe_en.sh"
     > non_en_script="prepro_post_dedupe.sh"
{
	tar --extract --gzip --verbose --file=${tarball} --strip-components=1

	sed --in-place="" "s,SCRIPTS=scripts,SCRIPTS=$(pwd)/scripts," prepro_post_dedupe_en.sh 
}
