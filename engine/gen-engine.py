import m17n
_exec = "/usr/libexec/ibus-engine-m17n %s:%s"
_icon = "ibus-m17n"
_author = ""
_credits = ""

for name, lang in m17n.minput_list_ims ():
	file_name = "m17n.%s.%s.engine" % (lang, name)
	out = file (file_name, "w")
	print >> out, "Exec=\"%s\"" % (_exec % (lang, name))
	print >> out, "Name=\"%s\"" % name
	print >> out, "Lang=\"%s\"" % lang
	print >> out, "Icon=\"%s\"" % _icon
	print >> out, "Author=\"%s\"" % _author
	print >> out, "Credits=\"%s\"" % _credits
