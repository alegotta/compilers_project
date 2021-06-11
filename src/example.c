// program: declarations statements RETURN SEMI functions
// main function (declarations statements)
// declarations
int i;                    // simple variable
char c = 'c';             // one with init
float val = 2.5;

for(i = 0; i < 10; i++){ // for
	if(i > 5){ // if-else
    	break;
	}
	else if(i == 5){
		i = 2 * i;
		val = func1();
		print(res[i]);
		print("\n");
		continue;
	}
	else{
    	        val = res[i];
   	 	print(res[i]);
    	        print("\n");
    	        p = p + 1;
	}

	if(i == 2 && val == 4.5){ // if
		print("iteration: 3\n");
	}
}
while(i < 12){ // while
	print(i);
	print(" ");
	func2(c);
	i++;
}
print("\n");
