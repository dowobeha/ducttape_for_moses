global {
       ducttape_experimental_packages=true
}

package moses :: .versioner=git .repo="git@github.com:moses-smt/mosesdecoder.git" .ref="remotes/origin/RELEASE-3.0"
# .ref="5244a7b6075cc7b292e475c43d23c68797e8e9c0"
{
	echo "hi"
}

task foo : moses 
{
	echo $moses
}
