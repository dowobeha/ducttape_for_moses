func download
     :: url
     :: downloader
     :: downloader_flags
     > out
{
	date +"Begin %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

	${downloader} ${downloader_flags} ${url} 

	date +"End %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
}



func symlink
     < in
     > out
{
	date +"Begin %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

	ln -s ${in} ${out}

	date +"End %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
}


func copy
     < in
     > out
{

	date +"Begin %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

	cp --verbose ${in} ${out}

	date +"End %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
}



func extract_from_tarball
     < tarball
    :: extract
     > out
{
	tar --extract         \
            --verbose         \
            --gzip            \
            --file=${tarball} \
	    ${extract}
}
